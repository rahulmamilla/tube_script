from firebase_functions import https_fn
from firebase_admin import firestore
import requests
from youtube_transcript_api import YouTubeTranscriptApi
from google.oauth2 import service_account
import google.auth.transport.requests
import datetime
from firebase_functions import scheduler_fn
import firebase_admin
import pytz
from functions_framework import logging as _logging
import urllib.parse

app = firebase_admin.initialize_app()


@https_fn.on_request(region="asia-south1", max_instances=10, enforce_app_check=True)
def get_video_details(req: https_fn.Request):
    try:
        SCOPES = [
            "https://www.googleapis.com/auth/youtube.readonly",
            "https://www.googleapis.com/auth/youtube.force-ssl",
        ]
        SERVICE_ACCOUNT_FILE = "service_account_file.json" #Path to service account file
        credentials = service_account.Credentials.from_service_account_file(
            SERVICE_ACCOUNT_FILE, scopes=SCOPES
        )
        request = google.auth.transport.requests.Request()
        credentials.refresh(request)
        token = credentials.token
        channelId = req.args.get("channelId")
        pageToken = req.args.get("pageToken")
        publishedAfter = req.args.get("publishedAfter")
        headers = {"Authorization": "Bearer %s" % token, "Accept": "application/json"}
        if publishedAfter == None:
            indiaTz = pytz.timezone("Asia/Kolkata")
            yesterday = datetime.datetime.combine(
                datetime.datetime.now(), datetime.time.min
            ) - datetime.timedelta(days=1)
            publishedAfter = indiaTz.localize(yesterday).isoformat()
            publishedAfter = urllib.parse.quote(publishedAfter.encode("utf-8"))
        if channelId != None:
            url = (
                f"https://youtube.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=50&publishedAfter={publishedAfter}&order=date&channelId={channelId}"
                if pageToken == None
                else f"https://youtube.googleapis.com/youtube/v3/search?part=snippet&type=video&order=date&maxResults=50&publishedAfter={publishedAfter}&channelId={channelId}&pageToken={pageToken}"
            )
            response = requests.request("GET", url, headers=headers)
            if response.status_code == 200:
                for vid in response.json()["items"]:
                    host = "" #Firebase Transcript Function URL
                    transcript_url = f"{host}?video_id={vid['id']['videoId']}"
                    resp = requests.request("GET", transcript_url)
                    transcript = ""
                    if resp.status_code == 200:
                        transcript = resp.json()["transcript"]
                    else:
                        print(
                            f"Error in generating transcript for video {vid['id']['videoId']}.Error: {response.json()}"
                        )
                    if transcript != "":
                        map = {
                            "title": vid["snippet"]["title"],
                            "thumbnail": vid["snippet"]["thumbnails"]["high"]["url"],
                            "date": datetime.datetime.fromisoformat(
                                vid["snippet"]["publishTime"]
                            ),
                            "transcript": transcript,
                        }
                        firestore.client().collection("channels").document(
                            channelId
                        ).collection("videos").document(vid["id"]["videoId"]).set(map)
                        print(
                            f"Uploaded video details of channel: {channelId}, Video: {vid['id']['videoId']}"
                        )
                    else:
                        print(
                            f"Transcript not available for video: {vid['id']['videoId']}"
                        )
                    if "nextPageToken" in response.json():
                        host = "" #Firebase Video Details Function URL
                        get_video_details_url = f"{host}?channelId={channelId}&pageToken={response.json()['nextPageToken']}"
                        response = requests.request("GET", get_video_details_url)
                        if response.status_code == 200:
                            {"message": "OK"}, 200, {"Content-Type": "application/json"}
                        else:
                            return (
                                {"Error in getting video details. Error:": e},
                                500,
                                {"Content-Type": "application/json"},
                            )
                    else:
                        return (
                            {"message": "OK"},
                            200,
                            {"Content-Type": "application/json"},
                        )
                return (
                    {"message": "OK"},
                    200,
                    {"Content-Type": "application/json"},
                )
            else:
                print(
                    f"Error in getting videos from channel:{channelId}. Response: {response.json()}"
                )
                return (
                    {
                        f"Error in getting videos from channel:{channelId}. Response: {response.json()}"
                    },
                    500,
                    {"Content-Type": "application/json"},
                )
    except Exception as e:
        print("Error in getting video details.Error", e)
        return (
            {"Error in getting video details. Error:": e},
            500,
            {"Content-Type": "application/json"},
        )


@https_fn.on_request(region="asia-south1", max_instances=10, enforce_app_check=True)
def yt_transcript(req: https_fn.Request):
    video_id = req.args.get("video_id")
    try:
        transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
        for trans in transcript_list:
            transcript_json = trans.translate("en").fetch()

        transcript = ""
        for i in transcript_json:
            transcript += i["text"] + " "
        return {"transcript": transcript}, 200, {"Content-Type": "application/json"}
    except Exception as e:
        print(f"Error in obtaining transcript : {e}")
        return (
            {"Error in obtaining transcript": e},
            500,
            {"Content-Type": "application/json"},
        )

@scheduler_fn.on_schedule(
    region="asia-south1",
    schedule="every day 00:00",
    timezone="Asia/Kolkata",
    max_instances=10,
)
def fetch_videos(event: scheduler_fn.ScheduledEvent):
    try:
        subscriptions = (
            firestore.client()
            .collection("subscriptions")
            .document("subscriptions")
            .get()
        )
        if subscriptions.exists:
            channels = subscriptions.to_dict()["subscriptions"]
            for channel in channels:
                host = "" #Firebase Get Video Details URL
                get_video_details_url = f"{host}?channelId={channel}"
                response = requests.request("GET", get_video_details_url, headers={})
                if response.status_code == 200:
                    print(f"Successfully fetched videos of channel: {channel}")
                else:
                    print(
                        f"Error in fetching videos of channel: {channel}. Error: {response.json()}"
                    )
            return (
                {"message": "Successfully fetched videos"},
                200,
                {"Content-Type": "application/json"},
            )
        else:
            print("Error: Subscriptions do not exist")
            return (
                {"error": "Error: Subscriptions do not exist"},
                500,
                {"Content-Type": "application/json"},
            )

    except Exception as e:
        print(f"Error in fetching videos. Error: {e}")
        return (
            {"error": f"Error in fetching videos. Error: {e}"},
            500,
            {"Content-Type": "application/json"},
        )
