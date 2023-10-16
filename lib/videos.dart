import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'providers/data_provider.dart';
import 'dart:math' as math;
import '../main.dart';

class Videos extends StatefulWidget {
  final String channelId;
  const Videos(this.channelId, {super.key});

  @override
  State<Videos> createState() => _VideosState();
}

class _VideosState extends State<Videos> {
  final PanelController _pc = PanelController();
  ScrollController sc = ScrollController();

  @override
  void initState() {
    super.initState();
    dp.fetchVideos(widget.channelId, reset: true);

    sc.addListener(() {
      if (sc.offset > sc.position.maxScrollExtent - 100) {
        dp.fetchVideos(widget.channelId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dp, child) {
        return Scaffold(
          body: SlidingUpPanel(
            controller: _pc,
            minHeight: 0,
            parallaxEnabled: true,
            backdropEnabled: true,
            isDraggable: true,
            onPanelClosed: () {
              dp.resetTranscriptVideoId();
            },
            panelBuilder: (sc) {
              return WillPopScope(
                  onWillPop: () async {
                    if (_pc.isPanelOpen) {
                      _pc.close();
                      return false;
                    } else {
                      return true;
                    }
                  },
                  child: Scaffold(
                    floatingActionButton: FloatingActionButton(
                      shape: const CircleBorder(),
                      onPressed: () {
                        sc.animateTo(-50.0,
                            duration: const Duration(seconds: 1),
                            curve: Curves.fastOutSlowIn);
                      },
                      child: const Icon(Icons.arrow_upward),
                    ),
                    body: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      controller: sc,
                      slivers: [
                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 12.0,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                width: 30,
                                height: 5,
                                decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(12.0))),
                              ),
                            ],
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 12.0,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Center(
                            child: ListTile(
                              leading: CircleAvatar(
                                  backgroundColor: Colors.black,
                                  backgroundImage: NetworkImage(
                                      dp.getChannelThumbnail(widget.channelId)),
                                  radius: 24),
                              title: Text(dp.getTranscriptVideoId() != ""
                                  ? dp.getVideoTitle(dp.getTranscriptVideoId())
                                  : ""),
                              subtitle: Text(dp.getTranscriptVideoId() != ""
                                  ? "${dp.getVideoDate(dp.getTranscriptVideoId())}"
                                  : ""),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      dp.markAsRead(widget.channelId,
                                          dp.getTranscriptVideoId());
                                    },
                                    isSelected: dp.isMarkedAsRead(
                                        widget.channelId,
                                        dp.getTranscriptVideoId()),
                                    tooltip: 'Mark as read',
                                    icon: Icon(MdiIcons.checkOutline),
                                    selectedIcon: Icon(MdiIcons.checkBold),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      dp.bookmark(widget.channelId,
                                          dp.getTranscriptVideoId());
                                    },
                                    isSelected: dp.isBookmarked(
                                        widget.channelId,
                                        dp.getTranscriptVideoId()),
                                    tooltip: 'Bookmark',
                                    icon: const Icon(Icons.bookmark_border),
                                    selectedIcon: const Icon(Icons.bookmark),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 8.0,
                          ),
                        ),
                        SliverToBoxAdapter(
                            child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: SelectionArea(
                                    child: dp.getHighlights()[
                                                dp.getTranscriptVideoId()] !=
                                            null
                                        ? TextHighlight(
                                            text: dp.getTranscriptVideoId() !=
                                                    ""
                                                ? dp.getTranscript(
                                                    dp.getTranscriptVideoId())
                                                : "",
                                            words: dp.getHighlights()[
                                                dp.getTranscriptVideoId()],
                                          )
                                        : Text(dp.getTranscriptVideoId() != ""
                                            ? dp.getTranscript(
                                                dp.getTranscriptVideoId())
                                            : ""),
                                    contextMenuBuilder: (
                                      BuildContext context,
                                      SelectableRegionState
                                          selectableRegionState,
                                    ) {
                                      return AdaptiveTextSelectionToolbar
                                          .buttonItems(
                                        anchors: selectableRegionState
                                            .contextMenuAnchors,
                                        buttonItems: <ContextMenuButtonItem>[
                                          ContextMenuButtonItem(
                                            type: ContextMenuButtonType.copy,
                                            onPressed: () {
                                              selectableRegionState.copy();
                                              selectableRegionState
                                                  .clearSelection();
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text(
                                                          "Text copied to clipboard")));
                                            },
                                            label: 'Copy',
                                          ),
                                          (() {
                                            String selectedText =
                                                selectableRegionState
                                                    .getSelectedText();
                                            if (!dp.getHighlights().containsKey(dp
                                                    .getTranscriptVideoId()) ||
                                                !dp
                                                    .getHighlights()[dp
                                                        .getTranscriptVideoId()]
                                                    .containsKey(
                                                        selectedText)) {
                                              return ContextMenuButtonItem(
                                                onPressed: () {
                                                  String highlight =
                                                      selectableRegionState
                                                          .getSelectedText();
                                                  selectableRegionState
                                                      .clearSelection();
                                                  dp.highlight(
                                                      widget.channelId,
                                                      dp.getTranscriptVideoId(),
                                                      highlight);
                                                },
                                                label: 'Highlight',
                                              );
                                            } else {
                                              return ContextMenuButtonItem(
                                                onPressed: () {
                                                  String highlight =
                                                      selectableRegionState
                                                          .getSelectedText();
                                                  selectableRegionState
                                                      .clearSelection();
                                                  dp.highlight(
                                                      widget.channelId,
                                                      dp.getTranscriptVideoId(),
                                                      highlight,
                                                      removeHighlight: true);
                                                },
                                                label: 'Undo Highlight',
                                              );
                                            }
                                          }())
                                        ],
                                      );
                                    }))),
                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 80.0,
                          ),
                        ),
                      ],
                    ),
                  ));
            },
            body: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                controller: sc,
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                      child: Center(
                    child: ConstrainedBox(
                        constraints: BoxConstraints.tight(const Size(80, 80)),
                        child: Hero(
                          tag: 'channel_thumbnail_${widget.channelId}',
                          child: CircleAvatar(
                            backgroundColor: Colors.black,
                            backgroundImage: NetworkImage(
                              dp.getChannelThumbnail(widget.channelId),
                            ),
                          ),
                        )),
                  )),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverToBoxAdapter(
                      child: Center(
                          child:
                              Text('${dp.getChannelTitle(widget.channelId)}'))),
                  const SliverToBoxAdapter(child: SizedBox(height: 2)),
                  SliverToBoxAdapter(
                      child: Center(
                    child: Text(
                        '${dp.getNumberOfVideos(widget.channelId)} videos'),
                  )),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverPersistentHeader(
                    floating: true,
                    delegate: _SliverAppBarDelegate(
                      minHeight: 60,
                      maxHeight: 40,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const SizedBox(
                            width: 8.0,
                          ),
                          ListView.separated(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dp.getVideoChips().length,
                              separatorBuilder: (context, index) {
                                return const SizedBox(width: 10.0);
                              },
                              itemBuilder: (context, index) {
                                return ChoiceChip(
                                  label: Text(dp.getVideoChips()[index]),
                                  selected: dp.selectedVideoChipIndex == index
                                      ? true
                                      : false,
                                  onSelected: (value) {
                                    dp.selectVideoChip(index);
                                    dp.fetchVideos(widget.channelId,
                                        reset: true);
                                  },
                                  showCheckmark: false,
                                );
                              }),
                          const SizedBox(
                            width: 8.0,
                          ),
                        ]),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                    return ListTile(
                      leading: SizedBox(
                          width: 40,
                          height: 40,
                          child: CachedNetworkImage(
                            placeholder: (context, url) {
                              return CircleAvatar(
                                  backgroundColor: Colors.black,
                                  backgroundImage: NetworkImage(
                                      dp.getChannelThumbnail(widget.channelId)),
                                  radius: 24);
                            },
                            imageUrl: dp.getVideoThumbnail(
                                dp.getVideos().keys.toList()[index]),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          )),
                      title: Text(dp
                          .getVideoTitle(dp.getVideos().keys.toList()[index])),
                      subtitle: Text(
                          dp.getVideoDate(dp.getVideos().keys.toList()[index])),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              dp.markAsRead(widget.channelId,
                                  dp.getVideos().keys.toList()[index]);
                            },
                            isSelected: dp.isMarkedAsRead(widget.channelId,
                                dp.getVideos().keys.toList()[index]),
                            tooltip: 'Mark as read',
                            icon: Icon(MdiIcons.checkOutline),
                            selectedIcon: Icon(MdiIcons.checkBold),
                          ),
                          IconButton(
                            onPressed: () {
                              dp.bookmark(widget.channelId,
                                  dp.getVideos().keys.toList()[index]);
                            },
                            isSelected: dp.isBookmarked(widget.channelId,
                                dp.getVideos().keys.toList()[index]),
                            tooltip: 'Bookmark',
                            icon: const Icon(Icons.bookmark_border),
                            selectedIcon: const Icon(Icons.bookmark),
                          ),
                        ],
                      ),
                      onTap: () {
                        if (dp.selectedVideoTileIndex != -1) {
                          dp.videoTileDeselect();
                        } else {
                          dp.setTranscriptVideoId(
                              dp.getVideos().keys.toList()[index]);
                          _pc.open();
                        }
                      },
                      onLongPress: () {
                        dp.videoLongPressed(
                            dp.getVideos().keys.toList()[index], index);
                        showModalBottomSheet<void>(
                          context: context,
                          builder: (context) {
                            return BottomSheet(
                              onClosing: () {},
                              builder: (context) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: dp.getVideoActions(context),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  }, childCount: dp.getVideos().length))
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => math.max(maxHeight, minHeight);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
