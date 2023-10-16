import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DataProvider with ChangeNotifier {
  //✨ Channels
  List<DocumentSnapshot> channelDocuments = [];
  Map channels = {};
  int numOfChannels = 0;

  fetchChannels({reset = false}) async {
    if (reset) {
      channels = {};
      channelDocuments = [];
    }
    FirebaseFirestore db = FirebaseFirestore.instance;
    final channelsCollection = db.collection("channels");
    channelsCollection.count().get().then((value) {
      numOfChannels = value.count;
      notifyListeners();
    });
    if (selectedChannelChipIndex != -1) {
      switch (channelChips[selectedChannelChipIndex]) {
        case "Today":
          {
            DateTime now = DateTime.now();
            now = DateTime(now.year, now.month, now.day);
            var query = channelDocuments.isNotEmpty
                ? channelsCollection.startAfterDocument(channelDocuments.last)
                : channelsCollection;
            query.get().then((querySnapshot) {
              Map<String, dynamic> map = {};
              channelDocuments.addAll(querySnapshot.docs);
              for (var docSnapshot in querySnapshot.docs) {
                Map<String, dynamic> details =
                    Map.fromEntries(docSnapshot.data().entries);
                db
                    .collection('channels/${docSnapshot.id}/videos')
                    .where("date",
                        isGreaterThanOrEqualTo: Timestamp.fromDate(now))
                    .count()
                    .get()
                    .then((value) {
                  if (value.count > 0) {
                    map[docSnapshot.id] = details;
                    map[docSnapshot.id]["numOfVideos"] = value.count;
                    map[docSnapshot.id]["channelId"] = docSnapshot.id;
                  }
                  if (map.isNotEmpty) channels.addAll(map);
                }).then((value) {
                  notifyListeners();
                });
              }
            });
            break;
          }
        case "Yesterday":
          {
            DateTime now = DateTime.now();
            now = DateTime(now.year, now.month, now.day);
            DateTime yesterday = DateTime(now.year, now.month, now.day - 1);
            var query = channelDocuments.isNotEmpty
                ? channelsCollection.startAfterDocument(channelDocuments.last)
                : channelsCollection;
            query.get().then((querySnapshot) {
              Map<String, dynamic> map = {};
              channelDocuments.addAll(querySnapshot.docs);
              for (var docSnapshot in querySnapshot.docs) {
                Map<String, dynamic> details =
                    Map.fromEntries(docSnapshot.data().entries);
                db
                    .collection('channels/${docSnapshot.id}/videos')
                    .where("date",
                        isGreaterThanOrEqualTo: Timestamp.fromDate(yesterday))
                    .where("date", isLessThan: Timestamp.fromDate(now))
                    .count()
                    .get()
                    .then((value) {
                  if (value.count > 0) {
                    map[docSnapshot.id] = details;
                    map[docSnapshot.id]["numOfVideos"] = value.count;
                    map[docSnapshot.id]["channelId"] = docSnapshot.id;
                  }
                  if (map.isNotEmpty) channels.addAll(map);
                }).then((value) {
                  notifyListeners();
                });
              }
            });
            break;
          }
        case "This Week":
          {
            DateTime now = DateTime.now();
            now = DateTime(now.year, now.month, now.day);
            DateTime recentSunday = DateTime(
                now.year, now.month, (now.day - (now.weekday - 7) % 7));
            var query = channelDocuments.isNotEmpty
                ? channelsCollection.startAfterDocument(channelDocuments.last)
                : channelsCollection;
            query.get().then((querySnapshot) {
              Map<String, dynamic> map = {};
              channelDocuments.addAll(querySnapshot.docs);
              for (var docSnapshot in querySnapshot.docs) {
                Map<String, dynamic> details =
                    Map.fromEntries(docSnapshot.data().entries);
                db
                    .collection('channels/${docSnapshot.id}/videos')
                    .where("date",
                        isGreaterThanOrEqualTo:
                            Timestamp.fromDate(recentSunday))
                    .where("date", isLessThan: Timestamp.fromDate(now))
                    .count()
                    .get()
                    .then((value) {
                  if (value.count > 0) {
                    map[docSnapshot.id] = details;
                    map[docSnapshot.id]["numOfVideos"] = value.count;
                    map[docSnapshot.id]["channelId"] = docSnapshot.id;
                  }
                  if (map.isNotEmpty) channels.addAll(map);
                }).then((value) {
                  notifyListeners();
                });
              }
            });
            break;
          }
        case "This Month":
          {
            DateTime now = DateTime.now();
            now = DateTime(now.year, now.month, now.day);
            DateTime monthStart = DateTime(now.year, now.month);
            var query = channelDocuments.isNotEmpty
                ? channelsCollection.startAfterDocument(channelDocuments.last)
                : channelsCollection;
            query.get().then((querySnapshot) {
              Map<String, dynamic> map = {};
              channelDocuments.addAll(querySnapshot.docs);
              for (var docSnapshot in querySnapshot.docs) {
                Map<String, dynamic> details =
                    Map.fromEntries(docSnapshot.data().entries);
                db
                    .collection('channels/${docSnapshot.id}/videos')
                    .where("date",
                        isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
                    .where("date", isLessThanOrEqualTo: Timestamp.fromDate(now))
                    .count()
                    .get()
                    .then((value) {
                  if (value.count > 0) {
                    map[docSnapshot.id] = details;
                    map[docSnapshot.id]["numOfVideos"] = value.count;
                    map[docSnapshot.id]["channelId"] = docSnapshot.id;
                  }
                  if (map.isNotEmpty) channels.addAll(map);
                }).then((value) {
                  notifyListeners();
                });
              }
            });
            break;
          }
        case "This Year":
          {
            DateTime now = DateTime.now();
            DateTime thisYear = DateTime(now.year);
            var query = channelDocuments.isNotEmpty
                ? channelsCollection.startAfterDocument(channelDocuments.last)
                : channelsCollection;
            query.get().then((querySnapshot) {
              Map<String, dynamic> map = {};
              channelDocuments.addAll(querySnapshot.docs);
              for (var docSnapshot in querySnapshot.docs) {
                Map<String, dynamic> details =
                    Map.fromEntries(docSnapshot.data().entries);
                db
                    .collection('channels/${docSnapshot.id}/videos')
                    .where("date",
                        isGreaterThanOrEqualTo: Timestamp.fromDate(thisYear))
                    .where("date", isLessThanOrEqualTo: Timestamp.fromDate(now))
                    .count()
                    .get()
                    .then((value) {
                  if (value.count > 0) {
                    map[docSnapshot.id] = details;
                    map[docSnapshot.id]["numOfVideos"] = value.count;
                    map[docSnapshot.id]["channelId"] = docSnapshot.id;
                  }
                  if (map.isNotEmpty) channels.addAll(map);
                }).then((value) {
                  notifyListeners();
                });
              }
            });
            break;
          }
        case "Last Year":
          {
            DateTime now = DateTime.now();
            DateTime lastYear = DateTime(now.year - 1);
            DateTime thisYear = DateTime(now.year);
            var query = channelDocuments.isNotEmpty
                ? channelsCollection.startAfterDocument(channelDocuments.last)
                : channelsCollection;
            query.get().then((querySnapshot) {
              Map<String, dynamic> map = {};
              channelDocuments.addAll(querySnapshot.docs);
              for (var docSnapshot in querySnapshot.docs) {
                Map<String, dynamic> details =
                    Map.fromEntries(docSnapshot.data().entries);
                db
                    .collection('channels/${docSnapshot.id}/videos')
                    .where("date",
                        isGreaterThanOrEqualTo: Timestamp.fromDate(lastYear))
                    .where("date",
                        isLessThanOrEqualTo: Timestamp.fromDate(thisYear))
                    .count()
                    .get()
                    .then((value) {
                  if (value.count > 0) {
                    map[docSnapshot.id] = details;
                    map[docSnapshot.id]["numOfVideos"] = value.count;
                    map[docSnapshot.id]["channelId"] = docSnapshot.id;
                  }
                  if (map.isNotEmpty) channels.addAll(map);
                }).then((value) {
                  notifyListeners();
                });
              }
            });
            break;
          }
      }
    } else {
      var query = channelDocuments.isNotEmpty
          ? channelsCollection
              .orderBy("title")
              .startAfterDocument(channelDocuments.last)
              .limit(10)
          : channelsCollection.orderBy("title").limit(10);
      query.get().then((querySnapshot) {
        channelDocuments.addAll(querySnapshot.docs);
        for (var docSnapshot in querySnapshot.docs) {
          Map<String, dynamic> details =
              Map.fromEntries(docSnapshot.data().entries);
          channels[docSnapshot.id] = details;
          channels[docSnapshot.id]["channelId"] = docSnapshot.id;
        }
        notifyListeners();
        for (var docSnapshot in querySnapshot.docs) {
          db.collection('channels/${docSnapshot.id}/videos').count().get().then(
            (value) {
              channels[docSnapshot.id]["numOfVideos"] = value.count;
            },
            onError: (e) => print("Error completing: $e"), //TODO: Handle Error
          ).then((value) {
            notifyListeners();
          });
        }
      });
    }
  }

  List getChannels() {
    if (channels.isNotEmpty) {
      return channels.keys.toList();
    }
    return [];
  }

  getChannelTitle(channelId) {
    var unescape = HtmlUnescape();
    return unescape.convert(channels[channelId]['title']);
  }

  getChannelThumbnail(channelId) {
    return channels[channelId]['thumbnail'];
  }

  getChannelActions(context) {
    if (selectedChannelTileIndex != -1) {
      return [
        IconButton(
            onPressed: () {
              directToYoutubeChannel(context);
              channelTileDeselect();
            },
            icon: Icon(MdiIcons.youtube)),
        IconButton(
            onPressed: () async => await Clipboard.setData(
                        ClipboardData(text: longPressedChannelId))
                    .then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Channel ID copied to clipboard"),
                    behavior: SnackBarBehavior.floating,
                  ));
                  channelTileDeselect();
                }),
            icon: const Icon(Icons.copy))
      ];
    } else {
      return null;
    }
  }

  getNumberOfVideos(channelId, {channelsPage = false}) {
    if (channelsPage) {
      return channels[channelId]["numOfVideos"];
    } else {
      return numOfVideos;
    }
  }

  //✨ Videos
  Map videos = {};
  int numOfVideos = 0;
  List<DocumentSnapshot> videoDocuments = [];
  fetchVideos(channelId, {reset = false}) async {
    if (reset) {
      videos = {};
      videoDocuments = [];
    }
    FirebaseFirestore db = FirebaseFirestore.instance;
    if (selectedVideoChipIndex != -1) {
      switch (videoChips[selectedVideoChipIndex]) {
        case "Today":
          {
            DateTime now = DateTime.now();
            now = DateTime(now.year, now.month, now.day);
            db
                .collection('channels/$channelId/videos')
                .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(now))
                .count()
                .get()
                .then((value) {
              numOfVideos = value.count;
            });
            var query = videoDocuments.isNotEmpty
                ? db
                    .collection('channels/$channelId/videos')
                    .orderBy("date", descending: true)
                    .startAfterDocument(videoDocuments.last)
                    .where("date",
                        isGreaterThanOrEqualTo: Timestamp.fromDate(now))
                    .limit(10)
                : db
                    .collection('channels/$channelId/videos')
                    .orderBy("date", descending: true)
                    .where("date",
                        isGreaterThanOrEqualTo: Timestamp.fromDate(now))
                    .limit(10);

            query.get().then((querySnapshot) {
              Map<String, dynamic> map = {};
              videoDocuments.addAll(querySnapshot.docs);
              for (var docSnapshot in querySnapshot.docs) {
                Map<String, dynamic> details =
                    Map.fromEntries(docSnapshot.data().entries);
                map[docSnapshot.id] = details;
              }
              if (map.isNotEmpty) videos.addAll(map);
            }).then((value) {
              notifyListeners();
            });
          }
        case "Yesterday":
          {
            DateTime now = DateTime.now();
            now = DateTime(now.year, now.month, now.day);
            DateTime yesterday = DateTime(now.year, now.month, now.day - 1);
            db
                .collection('channels/$channelId/videos')
                .where("date",
                    isGreaterThanOrEqualTo: Timestamp.fromDate(yesterday))
                .where("date", isLessThan: Timestamp.fromDate(now))
                .count()
                .get()
                .then((value) {
              numOfVideos = value.count;
            });
            var query = videoDocuments.isNotEmpty
                ? db
                    .collection('channels/$channelId/videos')
                    .orderBy("date", descending: true)
                    .startAfterDocument(videoDocuments.last)
                    .where("date",
                        isGreaterThanOrEqualTo: Timestamp.fromDate(yesterday))
                    .where("date", isLessThan: Timestamp.fromDate(now))
                    .limit(10)
                : db
                    .collection('channels/$channelId/videos')
                    .orderBy("date", descending: true)
                    .where("date",
                        isGreaterThanOrEqualTo: Timestamp.fromDate(yesterday))
                    .where("date", isLessThan: Timestamp.fromDate(now))
                    .limit(10);

            query.get().then((querySnapshot) {
              Map<String, dynamic> map = {};
              videoDocuments.addAll(querySnapshot.docs);
              for (var docSnapshot in querySnapshot.docs) {
                Map<String, dynamic> details =
                    Map.fromEntries(docSnapshot.data().entries);
                map[docSnapshot.id] = details;
              }
              if (map.isNotEmpty) videos.addAll(map);
            }).then((value) {
              notifyListeners();
            });
          }
        case "This Week":
          {
            DateTime now = DateTime.now();
            now = DateTime(now.year, now.month, now.day);
            DateTime recentSunday = DateTime(
                now.year, now.month, (now.day - (now.weekday - 7) % 7));
            db
                .collection('channels/$channelId/videos')
                .where("date",
                    isGreaterThanOrEqualTo: Timestamp.fromDate(recentSunday))
                .where("date", isLessThan: Timestamp.fromDate(now))
                .count()
                .get()
                .then((value) {
              numOfVideos = value.count;
            });
            var query = videoDocuments.isNotEmpty
                ? db
                    .collection('channels/$channelId/videos')
                    .orderBy("date", descending: true)
                    .startAfterDocument(videoDocuments.last)
                    .where("date",
                        isGreaterThanOrEqualTo:
                            Timestamp.fromDate(recentSunday))
                    .where("date", isLessThan: Timestamp.fromDate(now))
                    .limit(10)
                : db
                    .collection('channels/$channelId/videos')
                    .orderBy("date", descending: true)
                    .where("date",
                        isGreaterThanOrEqualTo:
                            Timestamp.fromDate(recentSunday))
                    .where("date", isLessThan: Timestamp.fromDate(now))
                    .limit(10);

            query.get().then((querySnapshot) {
              Map<String, dynamic> map = {};
              videoDocuments.addAll(querySnapshot.docs);
              for (var docSnapshot in querySnapshot.docs) {
                Map<String, dynamic> details =
                    Map.fromEntries(docSnapshot.data().entries);
                map[docSnapshot.id] = details;
              }
              if (map.isNotEmpty) videos.addAll(map);
            }).then((value) {
              notifyListeners();
            });
          }
        case "This Month":
          {
            DateTime now = DateTime.now();
            now = DateTime(now.year, now.month, now.day);
            DateTime monthStart = DateTime(now.year, now.month);
            db
                .collection('channels/$channelId/videos')
                .where("date",
                    isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
                .where("date", isLessThan: Timestamp.fromDate(now))
                .count()
                .get()
                .then((value) {
              numOfVideos = value.count;
            });
            var query = videoDocuments.isNotEmpty
                ? db
                    .collection('channels/$channelId/videos')
                    .orderBy("date", descending: true)
                    .startAfterDocument(videoDocuments.last)
                    .where("date",
                        isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
                    .where("date", isLessThan: Timestamp.fromDate(now))
                    .limit(10)
                : db
                    .collection('channels/$channelId/videos')
                    .orderBy("date", descending: true)
                    .where("date",
                        isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
                    .where("date", isLessThan: Timestamp.fromDate(now))
                    .limit(10);

            query.get().then((querySnapshot) {
              Map<String, dynamic> map = {};
              videoDocuments.addAll(querySnapshot.docs);
              for (var docSnapshot in querySnapshot.docs) {
                Map<String, dynamic> details =
                    Map.fromEntries(docSnapshot.data().entries);
                map[docSnapshot.id] = details;
              }
              if (map.isNotEmpty) videos.addAll(map);
            }).then((value) {
              notifyListeners();
            });
          }
        case "This Year":
          {
            DateTime now = DateTime.now();
            now = DateTime(now.year, now.month, now.day);
            DateTime thisYear = DateTime(now.year);
            db
                .collection('channels/$channelId/videos')
                .where("date",
                    isGreaterThanOrEqualTo: Timestamp.fromDate(thisYear))
                .where("date", isLessThan: Timestamp.fromDate(now))
                .count()
                .get()
                .then((value) {
              numOfVideos = value.count;
            });
            var query = videoDocuments.isNotEmpty
                ? db
                    .collection('channels/$channelId/videos')
                    .orderBy("date", descending: true)
                    .startAfterDocument(videoDocuments.last)
                    .where("date",
                        isGreaterThanOrEqualTo: Timestamp.fromDate(thisYear))
                    .where("date", isLessThan: Timestamp.fromDate(now))
                    .limit(10)
                : db
                    .collection('channels/$channelId/videos')
                    .orderBy("date", descending: true)
                    .where("date",
                        isGreaterThanOrEqualTo: Timestamp.fromDate(thisYear))
                    .where("date", isLessThan: Timestamp.fromDate(now))
                    .limit(10);

            query.get().then((querySnapshot) {
              Map<String, dynamic> map = {};
              videoDocuments.addAll(querySnapshot.docs);
              for (var docSnapshot in querySnapshot.docs) {
                Map<String, dynamic> details =
                    Map.fromEntries(docSnapshot.data().entries);
                map[docSnapshot.id] = details;
              }
              if (map.isNotEmpty) videos.addAll(map);
            }).then((value) {
              notifyListeners();
            });
          }
        case "Last Year":
          {
            DateTime now = DateTime.now();
            now = DateTime(now.year, now.month, now.day);
            DateTime lastYear = DateTime(now.year - 1);
            DateTime thisYear = DateTime(now.year);
            db
                .collection('channels/$channelId/videos')
                .where("date",
                    isGreaterThanOrEqualTo: Timestamp.fromDate(lastYear))
                .where("date", isLessThan: Timestamp.fromDate(thisYear))
                .count()
                .get()
                .then((value) {
              numOfVideos = value.count;
            });
            var query = videoDocuments.isNotEmpty
                ? db
                    .collection('channels/$channelId/videos')
                    .orderBy("date", descending: true)
                    .startAfterDocument(videoDocuments.last)
                    .where("date",
                        isGreaterThanOrEqualTo: Timestamp.fromDate(lastYear))
                    .where("date", isLessThan: Timestamp.fromDate(thisYear))
                    .limit(10)
                : db
                    .collection('channels/$channelId/videos')
                    .orderBy("date", descending: true)
                    .where("date",
                        isGreaterThanOrEqualTo: Timestamp.fromDate(lastYear))
                    .where("date", isLessThan: Timestamp.fromDate(thisYear))
                    .limit(10);

            query.get().then((querySnapshot) {
              Map<String, dynamic> map = {};
              videoDocuments.addAll(querySnapshot.docs);
              for (var docSnapshot in querySnapshot.docs) {
                Map<String, dynamic> details =
                    Map.fromEntries(docSnapshot.data().entries);
                map[docSnapshot.id] = details;
              }
              if (map.isNotEmpty) videos.addAll(map);
            }).then((value) {
              notifyListeners();
            });
          }
        case "Bookmarks":
          {
            if (userData.containsKey(channelId)) {
              userData[channelId].forEach((videoId, details) {
                if (userData[channelId][videoId].containsKey("isBookmarked") &&
                    userData[channelId][videoId]["isBookmarked"]) {
                  var query =
                      db.collection('channels/$channelId/videos').doc(videoId);
                  query.get().then((docSnapshot) {
                    Map<String, dynamic> map = {};
                    map[docSnapshot.id] = docSnapshot.data();
                    if (map.isNotEmpty) videos.addAll(map);
                  }).then((value) {
                    notifyListeners();
                  });
                }
              });
            }
          }
        case "Marked as Read":
          {
            if (userData.containsKey(channelId)) {
              userData[channelId].forEach((videoId, details) {
                if (userData[channelId][videoId]
                        .containsKey("isMarkedAsRead") &&
                    userData[channelId][videoId]["isMarkedAsRead"]) {
                  var query =
                      db.collection('channels/$channelId/videos').doc(videoId);
                  query.get().then((docSnapshot) {
                    Map<String, dynamic> map = {};
                    map[docSnapshot.id] = docSnapshot.data();
                    if (map.isNotEmpty) videos.addAll(map);
                  }).then((value) {
                    notifyListeners();
                  });
                }
              });
            }
          }
        case "Highlighted":
          {
            if (userData.containsKey(channelId)) {
              userData[channelId].forEach((videoId, details) {
                if (userData[channelId][videoId].containsKey("highlights")) {
                  var query =
                      db.collection('channels/$channelId/videos').doc(videoId);
                  query.get().then((docSnapshot) {
                    Map<String, dynamic> map = {};
                    map[docSnapshot.id] = docSnapshot.data();
                    if (map.isNotEmpty) videos.addAll(map);
                  }).then((value) {
                    notifyListeners();
                  });
                }
              });
            }
          }
      }
    } else {
      db.collection('channels/$channelId/videos').count().get().then((value) {
        numOfVideos = value.count;
      });
      var query = videoDocuments.isNotEmpty
          ? db
              .collection('channels/$channelId/videos')
              .orderBy("date", descending: true)
              .startAfterDocument(videoDocuments.last)
              .limit(10)
          : db
              .collection('channels/$channelId/videos')
              .orderBy("date", descending: true)
              .limit(10);

      query.get().then((querySnapshot) {
        Map<String, dynamic> map = {};
        videoDocuments.addAll(querySnapshot.docs);
        for (var docSnapshot in querySnapshot.docs) {
          Map<String, dynamic> details =
              Map.fromEntries(docSnapshot.data().entries);
          map[docSnapshot.id] = details;
        }
        if (map.isNotEmpty) videos.addAll(map);
      }).then((value) {
        notifyListeners();
      });
    }
  }

  getVideos() {
    if (videos.isNotEmpty) {
      return videos;
    }
    return {};
  }

  getVideoTitle(videoId) {
    var unescape = HtmlUnescape();
    return unescape.convert(videos[videoId]['title']);
  }

  getVideoThumbnail(videoId) {
    return videos[videoId]['thumbnail'];
  }

  getVideoDate(videoId) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(
        videos[videoId]['date'].millisecondsSinceEpoch);
    date = date.toLocal();
    var formatter = DateFormat('dd MMM yyyy');
    var formattedDate = formatter.format(date);
    return formattedDate;
  }

  getVideoActions(context) {
    if (selectedVideoTileIndex != -1) {
      return [
        ListTile(
          leading: Icon(MdiIcons.youtube),
          title: const Text('Open Video in Youtube'),
          onTap: () {
            directToYoutubeChannel(context, video: true);
            videoTileDeselect();
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.copy),
          title: const Text('Copy Video ID'),
          onTap: () async =>
              Clipboard.setData(ClipboardData(text: longPressedVideoId))
                  .then((_) {
            videoTileDeselect();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Video ID copied to clipboard"),
              behavior: SnackBarBehavior.floating,
            ));
          }),
        ),
      ];
    } else {
      return null;
    }
  }

  //✨ Dark Mode
  bool isDarkMode = false;
  changeTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  //✨ Transcript
  String transcript = '';
  String transcriptVideoId = '';

  setTranscriptVideoId(videoId) {
    transcriptVideoId = videoId;
    notifyListeners();
  }

  getTranscript(videoId) {
    return videos[videoId]["transcript"];
  }

  getTranscriptVideoId() {
    return transcriptVideoId;
  }

  resetTranscriptVideoId() {
    transcriptVideoId = '';
    notifyListeners();
  }

//✨ Chips
  List<String> channelChips = [
    "Today",
    "Yesterday",
    "This Week",
    "This Month",
    "This Year",
    "Last Year"
  ];
  List<String> videoChips = [
    "Today",
    "Yesterday",
    "This Week",
    "This Month",
    "This Year",
    "Last Year",
    "Bookmarks",
    "Marked as Read",
    "Highlighted"
  ];
  int selectedChannelChipIndex = -1;
  int selectedVideoChipIndex = -1;

  getChannelChips() {
    return channelChips;
  }

  getVideoChips() {
    return videoChips;
  }

  selectChannelChip(index) {
    if (selectedChannelChipIndex == index) {
      selectedChannelChipIndex = -1;
    } else {
      selectedChannelChipIndex = index;
    }
    notifyListeners();
  }

  selectVideoChip(index) {
    if (selectedVideoChipIndex == index) {
      selectedVideoChipIndex = -1;
    } else {
      selectedVideoChipIndex = index;
    }
    notifyListeners();
  }

  deselectVideoChip() {
    selectedVideoChipIndex = -1;
    videos = {};
    numOfVideos = 0;
    videoDocuments = [];
    notifyListeners();
  }

  //✨ Bookmarks and Marked as done
  Map userData = {};
  bool isUserDataStale = false;
  Map<String, Map<String, HighlightedWord>> highlights = {};
  fetchUserData() async {
    final directory = await getApplicationDocumentsDirectory();
    if (File("${directory.path}/userData.json").existsSync()) {
      userData = json
          .decode(File("${directory.path}/userData.json").readAsStringSync());
      userData.forEach((channelId, vids) {
        vids.forEach((videoId, details) {
          if (details.containsKey("highlights")) {
            highlights[videoId] = {};
            for (var highlight in details["highlights"]) {
              highlights[videoId]![highlight] = HighlightedWord(
                  onTap: () {},
                  textStyle: const TextStyle(
                      backgroundColor: Colors.amber, color: Colors.black));
            }
          }
        });
      });
    } else {
      Map userMap = {};
      File userDataFile = File("${directory.path}/userData.json");
      userDataFile.writeAsStringSync(json.encode(userMap));
      userData = userMap;
    }
    notifyListeners();
  }

  markAsRead(channelId, videoId) {
    if (userData.containsKey(channelId)) {
      if (userData[channelId].containsKey(videoId)) {
        userData[channelId][videoId]['isMarkedAsRead'] =
            userData[channelId][videoId]['isMarkedAsRead'] == null
                ? true
                : !userData[channelId][videoId]['isMarkedAsRead'];
      } else {
        userData[channelId][videoId] = {};
        userData[channelId][videoId]['isMarkedAsRead'] = true;
      }
    } else {
      userData[channelId] = {};
      userData[channelId][videoId] = {};
      userData[channelId][videoId]['isMarkedAsRead'] = true;
    }
    isUserDataStale = true;
    notifyListeners();
  }

  bookmark(channelId, videoId) {
    if (userData.containsKey(channelId)) {
      if (userData[channelId].containsKey(videoId)) {
        if (!userData[channelId][videoId].containsKey("isBookmarked")) {
          userData[channelId][videoId]['isBookmarked'] = true;
        } else {
          userData[channelId][videoId]['isBookmarked'] =
              !userData[channelId][videoId]['isBookmarked'];
        }
      } else {
        userData[channelId][videoId] = {};
        userData[channelId][videoId]['isBookmarked'] = true;
      }
    } else {
      userData[channelId] = {};
      userData[channelId][videoId] = {};
      userData[channelId][videoId]['isBookmarked'] = true;
    }
    isUserDataStale = true;
    notifyListeners();
  }

  highlight(channelId, videoId, highlight, {removeHighlight = false}) {
    if (userData.containsKey(channelId)) {
      if (userData[channelId].containsKey(videoId)) {
        if (!userData[channelId].containsKey('highlights')) {
          userData[channelId][videoId]['highlights'] = [];
        }
      } else {
        userData[channelId][videoId] = {};
        if (!userData[channelId].containsKey('highlights')) {
          userData[channelId][videoId]['highlights'] = [];
        }
      }
    } else {
      userData[channelId] = {};
      userData[channelId][videoId] = {};
      if (!userData[channelId].containsKey('highlights')) {
        userData[channelId][videoId]['highlights'] = [];
      }
    }
    if (removeHighlight) {
      if (userData[channelId][videoId]['highlights'].contains(highlight)) {
        userData[channelId][videoId]['highlights'].remove(highlight);
      }
      highlights[videoId]!.remove(highlight);
    } else {
      userData[channelId][videoId]['highlights'].add(highlight);
      if (!highlights.containsKey(videoId)) {
        highlights[videoId] = {};
      }
      highlights[videoId]![highlight] = HighlightedWord(
          onTap: () {},
          textStyle: const TextStyle(
              backgroundColor: Colors.amber, color: Colors.black));
    }
    isUserDataStale = true;
    notifyListeners();
  }

  getHighlights() {
    return highlights;
  }

  note(channelId, videoId, highlight, {removeHighlight = false}) {
    if (userData.containsKey(channelId)) {
      if (userData[channelId].containsKey(videoId)) {
        if (!userData[channelId].containsKey('notes')) {
          userData[channelId][videoId]['notes'] = [];
        }
      } else {
        userData[channelId][videoId] = {};
        if (!userData[channelId].containsKey('notes')) {
          userData[channelId][videoId]['notes'] = [];
        }
      }
    } else {
      userData[channelId] = {};
      userData[channelId][videoId] = {};
      if (!userData[channelId].containsKey('notes')) {
        userData[channelId][videoId]['notes'] = [];
      }
    }
    if (removeHighlight &&
        userData[channelId][videoId]['notes'].contains(highlight)) {
      userData[channelId][videoId]['notes'].remove(highlight);
    } else {
      userData[channelId][videoId]['notes'].add(highlight);
    }
    isUserDataStale = true;
    notifyListeners();
  }

  isMarkedAsRead(channelId, videoId) {
    if (userData.containsKey(channelId) &&
        userData[channelId].containsKey(videoId)) {
      return userData[channelId][videoId]['isMarkedAsRead'];
    }
    return false;
  }

  isBookmarked(channelId, videoId) {
    if (userData.containsKey(channelId) &&
        userData[channelId].containsKey(videoId)) {
      return userData[channelId][videoId]['isBookmarked'];
    }
    return false;
  }

  saveUserData() async {
    if (isUserDataStale) {
      final directory = await getApplicationDocumentsDirectory();
      File userDataFile = File("${directory.path}/userData.json");
      userDataFile.writeAsStringSync(json.encode(userData),
          mode: FileMode.writeOnly);
      isUserDataStale = false;
    }
  }

//✨ Long Press options
  bool isChannelLongPressed = false;
  bool isVideoLongPressed = false;
  String longPressedChannelId = '';
  String longPressedVideoId = '';
  int selectedChannelTileIndex = -1;
  int selectedVideoTileIndex = -1;
  channelLongPressed(channelId, index) {
    isChannelLongPressed = true;
    longPressedChannelId = channelId;
    selectedChannelTileIndex = index;
    notifyListeners();
  }

  videoLongPressed(videoId, index) {
    isVideoLongPressed = true;
    longPressedVideoId = videoId;
    selectedVideoTileIndex = index;
    notifyListeners();
  }

  channelTileDeselect() {
    selectedChannelTileIndex = -1;
    notifyListeners();
  }

  videoTileDeselect() {
    selectedVideoTileIndex = -1;
    notifyListeners();
  }

  isChannelTileSelected(int index) {
    if (index == selectedChannelTileIndex) {
      return true;
    }
    return false;
  }

  directToYoutubeChannel(context, {video = false}) async {
    if (video) {
      Uri url = Uri.parse('https://youtube.com/watch?v=$longPressedVideoId');
      if (!await launchUrl(url)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Unable to redirect to Youtube"),
          elevation: 2.0, //Controls the shadow below snack bar
          behavior: SnackBarBehavior
              .floating, //floating: Displayed above BottomNavigationBar, FloatingActionButton. fixed: Fixed to the bottom(Avoid fixed when there's FAB)
          onVisible: () {
            //Do something when snackbar is displayed
          },
          dismissDirection: DismissDirection
              .startToEnd, //startToEnd, horizontal, endToStart, down(default), up, none, vertical
        ));
      }
    } else {
      Uri url = Uri.parse('https://youtube.com/channel/$longPressedChannelId');
      if (!await launchUrl(url)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Unable to redirect to Youtube"),
          elevation: 2.0, //Controls the shadow below snack bar
          behavior: SnackBarBehavior
              .floating, //floating: Displayed above BottomNavigationBar, FloatingActionButton. fixed: Fixed to the bottom(Avoid fixed when there's FAB)
          onVisible: () {
            //Do something when snackbar is displayed
          },
          dismissDirection: DismissDirection
              .startToEnd, //startToEnd, horizontal, endToStart, down(default), up, none, vertical
        ));
      }
    }
  }

  DataProvider() {
    fetchUserData();
  }
}
