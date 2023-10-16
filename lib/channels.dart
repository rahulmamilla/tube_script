import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/data_provider.dart';
import 'videos.dart';
import '../main.dart';

class Channels extends StatefulWidget {
  const Channels({super.key});

  @override
  State<Channels> createState() => _ChannelsState();
}

class _ChannelsState extends State<Channels> with TickerProviderStateMixin {
  late ScrollController sc;
  @override
  void initState() {
    super.initState();
    dp.fetchChannels();
    sc = ScrollController();
    sc.addListener(() {
      if (sc.offset > sc.position.maxScrollExtent - 200) {
        dp.fetchChannels();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(builder: (context, dp, child) {
      return Scaffold(
        body: CustomScrollView(
          controller: sc,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              title: const Text('Channels'),
              floating: true,
              snap: true,
              expandedHeight: kToolbarHeight + 56,
              collapsedHeight: kToolbarHeight + 56,
              actions: dp.isChannelLongPressed
                  ? dp.getChannelActions(context)
                  : [
                      IconButton(
                          onPressed: () {
                            dp.changeTheme();
                          },
                          icon: dp.isDarkMode
                              ? const Icon(Icons.light_mode)
                              : const Icon(Icons.dark_mode))
                    ],
              flexibleSpace: Padding(
                padding: EdgeInsets.only(
                    top: (kToolbarHeight +
                        MediaQuery.of(context).viewPadding.top)),
                child: SizedBox(
                  height: 40.0,
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
                          itemCount: dp.getChannelChips().length,
                          separatorBuilder: (context, index) {
                            return const SizedBox(width: 10.0);
                          },
                          itemBuilder: (context, index) {
                            return ChoiceChip(
                              label: Text(dp.getChannelChips()[index]),
                              selected: dp.selectedChannelChipIndex == index
                                  ? true
                                  : false,
                              onSelected: (value) {
                                dp.selectChannelChip(index);
                                dp.fetchChannels(reset: true);
                              },
                              showCheckmark: false,
                            );
                          }),
                      const SizedBox(
                        width: 16.0,
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 8.0,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (dp.getChannels().length > index) {
                    String channelId = dp.getChannels()[index];
                    return ListTile(
                        selected: dp.isChannelTileSelected(index),
                        leading: Hero(
                          tag: 'channel_thumbnail_$channelId',
                          child: CircleAvatar(
                              backgroundColor: Colors.black,
                              backgroundImage: NetworkImage(
                                  dp.getChannelThumbnail(channelId),
                                  scale: 1),
                              radius: 24),
                        ),
                        title: Text('${dp.getChannelTitle(channelId)}'),
                        subtitle: Text(
                            '${dp.getNumberOfVideos(channelId, channelsPage: true)} videos'),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return Videos(channelId);
                            }));
                          },
                        ),
                        onLongPress: () {
                          dp.channelLongPressed(channelId, index);
                        },
                        selectedTileColor: Colors.blue.withOpacity(0.2),
                        onTap: () {
                          //✨ Remove
                          // query();
                          if (dp.selectedChannelTileIndex != -1) {
                            dp.channelTileDeselect();
                          } else {
                            HapticFeedback.heavyImpact();
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return Videos(channelId);
                            }));
                          }
                        });
                  } else {
                    return const ListTile();
                  }
                },
                childCount: dp.getChannels().length,
              ),
            )
          ],
        ),
      );
    });
  }
}
