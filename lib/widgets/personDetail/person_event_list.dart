import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:fluttergithub/common/myAvatar.dart';
import 'package:fluttergithub/common/net/NetApi.dart';
import 'package:fluttergithub/common/util/CommonUtil.dart';
import 'package:fluttergithub/common/util/RelativeDateUtil.dart';
import 'package:fluttergithub/common/util/ReposEventUtil.dart';
import 'package:fluttergithub/models/index.dart';
import 'package:fluttergithub/routes/CommitDetail/commit_detail_page.dart';
import 'package:fluttergithub/routes/CommitDetail/repo_event_push_list.dart';
import 'package:fluttergithub/routes/person_detail_page.dart';
import 'package:fluttergithub/routes/repo_detail_page.dart';
import 'package:fluttergithub/widgets/myWidgets/index.dart';

class PersonEventList extends StatefulWidget {
  PersonEventList({@required this.username});

  final String username;

  @override
  State<StatefulWidget> createState() {
    return _PersonEventListState();
  }
}

class _PersonEventListState extends State<PersonEventList>
    with AutomaticKeepAliveClientMixin {
  //导航栏切换时保持原有状态
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext mContext) {
    return MediaQuery.removePadding(
      removeTop: true,
      context: context,
      child: InfiniteListView<EventBean>(
        onRetrieveData: (int page, List<EventBean> items, bool refresh) async {
          var data = await NetApi(context).getUserEvents(
            userName: widget.username,
            queryParameters: {
              'page': page,
              'page_size': 30,
            },
          );
          //把请求到的新数据添加到items中
          items.addAll(data);
          // 如果接口返回的数量等于'page_size'，则认为还有数据，反之则认为最后一页
          return data.length == 30;
        },
        itemBuilder: (List list, int index, BuildContext ctx) {
          // 项目信息列表项
          return _eventItem(list[index], mContext);
        },
      ),
    );
  }

  Widget _eventItem(EventBean eventData, BuildContext context) {
    return GestureDetector(
      child: MyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                InkWell(
                    child: Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: myAvatar(
                        eventData.actor.avatar_url,
                        width: 36.0,
                        height: 36.0,
                        borderRadius: BorderRadius.circular(36),
                      ),
                    ),
                    onTap: () {
                      goToPage(
                          context: context,
                          page: PersonDetailPage(
                            name: eventData.actor.login,
                          ));
                    }),
                Expanded(
                  child: Text(
                    eventData.actor.login ?? "",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor),
                  ),
                ),
                Text(
                  RelativeDateFormat.format(
                      DateTime.parse(eventData.created_at)),
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                EventUtils.getActionAndDes(eventData)["actionStr"] ?? "",
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ),
            subText(eventData),
          ],
        ),
      ),
      onTap: () {
        var fullName = eventData.repo.name;
        int tag= fullName.indexOf('/');
        var reposOwner = fullName.substring(0,tag);
        var reposName = fullName.substring(tag+1);
        if (eventData.type == 'PushEvent' &&
            eventData.payload.commits.length > 0) {
          if (eventData.payload.commits.length == 1) {
            goToPage(
                context: context,
                page: CommitDetailPage(
                    reposOwner,
                    reposName,
                    eventData.payload.commits[0].sha,
                    eventData.payload.ref.substring(11)));
          } else {
            goToPage(
                context: context,
                page: EventPushListPage(
                    reposOwner, reposName, eventData.payload));
          }
        } else {
          goToPage(
              context: context,
              page: RepoDetailRoute(reposOwner,reposName));
        }
      },
    );
  }
}

Widget subText(EventBean data) {
  if (data.payload != null &&
      data.payload.commits != null &&
      data.payload.commits.length > 0) {
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: data.payload.commits.length,
      itemBuilder: (BuildContext context, int index) {
        return Text(
          data.payload.commits[index].message ?? "",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        );
      },
    );
  } else {
    return new Container(height: 0.0, width: 0.0);
  }
}
