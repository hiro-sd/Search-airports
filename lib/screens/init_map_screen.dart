import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ticket_app/riverpod/map_screen_state_notifier.dart';
import 'package:ticket_app/screens/airport_list_screen.dart';
import 'package:ticket_app/screens/search_window_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// 初めに表示するmapScreen
class InitMapScreen extends ConsumerWidget {
  const InitMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapScreenProvider);
    bool? whichTap;

    Future<void> openSearchWindow(String tmp) async {
      final placeDetails = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => whichTap!
              ? SearchWindow(
                  hintText:
                      AppLocalizations.of(context)!.search_departing_airport)
              : SearchWindow(
                  hintText: AppLocalizations.of(context)!.search_airport),
        ),
      );

      if (placeDetails != null && context.mounted) {
        final destination = LatLng(placeDetails['lat'], placeDetails['lng']);
        final placeName = placeDetails['name'];
        final placePhoto = placeDetails['photo_reference'];

        // GoogleMapをその位置に移動させる
        ref.read(mapScreenProvider.notifier).moveCameraToPosition(
              context,
              destination,
              placeName, // マーカーに表示するタイトル
              tmp,
            );

        // マーカーをタップした時の処理(ModalBottomSheetを表示)
        ref.read(mapScreenProvider.notifier).showMarkerDetails(
              context,
              ref,
              placeName,
              placePhoto,
              tmp,
            );
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          AppLocalizations.of(context)!.title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary, //Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: state.circleCenter,
              zoom: 9,
            ), // 初期位置
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            mapType: MapType.normal,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: false,
            markers: state.markers, // Riverpodの状態を参照
            onMapCreated: (GoogleMapController controller) {
              ref.read(mapScreenProvider.notifier).mapController = controller;
              ref.read(mapScreenProvider.notifier).getCurrentLocation();
            },
          ),
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.2), //Colors.blue.withOpacity(0.2),
                border: Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    width: 3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
              child: Column(children: [
            const SizedBox(height: 15),
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10.0,
                      spreadRadius: 1.0,
                      offset: Offset(10, 10))
                ],
              ),
              // 検索ウィンドウ
              child: TextButton(
                onPressed: () {
                  whichTap = true;
                  openSearchWindow('tmpTakeoff');
                },
                child: Row(children: [
                  const SizedBox(width: 7.5),
                  Icon(
                    state.tmpTakeoff ? Icons.flight_takeoff : Icons.search,
                    color: const Color.fromARGB(255, 100, 100, 100),
                  ),
                  const SizedBox(width: 17.5),
                  Flexible(
                    child: Text(
                      state.tmpTakeoff
                          ? state.selectedDeparture!
                          : AppLocalizations.of(context)!
                              .search_departing_airport,
                      style: TextStyle(
                          color: state.tmpTakeoff
                              ? Colors.black
                              : const Color.fromARGB(255, 100, 100, 100),
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10.0,
                      spreadRadius: 1.0,
                      offset: Offset(10, 10))
                ],
              ),
              child: TextButton(
                // 検索フォーム
                onPressed: () {
                  whichTap = false;
                  openSearchWindow('tmpLand');
                },
                child: Row(children: [
                  const SizedBox(width: 7.5),
                  Icon(
                    state.tmpLand ? Icons.flight_land : Icons.search,
                    color: const Color.fromARGB(255, 100, 100, 100),
                  ),
                  const SizedBox(width: 17.5),
                  Flexible(
                    child: Text(
                      state.tmpLand
                          ? state.selectedDestination!
                          : AppLocalizations.of(context)!.search_airport,
                      style: TextStyle(
                          color: state.tmpLand
                              ? Colors.black
                              : const Color.fromARGB(255, 100, 100, 100),
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
            )
          ])),
          Positioned(
            // 地図に表示されるマーカーを切り替えるボタン
            bottom: 90,
            right: 15,
            child: FloatingActionButton(
              heroTag: null, // Heroアニメーションを無効にする
              shape: const CircleBorder(),
              onPressed: () async {
                final notifier = ref.read(mapScreenProvider.notifier);

                if (!state.showAllAirports) {
                  // 全国の空港に切り替え
                  notifier.switchToAllAirports(generateMarkers(context, ref));
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(AppLocalizations.of(context)!.switch_map,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          content:
                              Text(AppLocalizations.of(context)!.show_airports),
                          actions: [
                            TextButton(
                              child: Text(AppLocalizations.of(context)!.close),
                              onPressed: () {
                                Navigator.of(context).pop(); // ダイアログを閉じる
                              },
                            ),
                          ],
                        );
                      });
                } else {
                  // 現在地周辺の空港に切り替え
                  await notifier.switchToNearbyAirports(context, ref);
                  showDialog(
                      // ignore: use_build_context_synchronously
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(AppLocalizations.of(context)!.switch_map,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          content: Text(AppLocalizations.of(context)!
                              .show_nearby_airports),
                          actions: [
                            TextButton(
                              child: Text(AppLocalizations.of(context)!.close),
                              onPressed: () {
                                Navigator.of(context).pop(); // ダイアログを閉じる
                              },
                            ),
                          ],
                        );
                      });
                }
              },
              //backgroundColor: Colors.white,
              child: const Icon(
                Icons.local_airport,
                size: 27.5,
                //color: Color.fromARGB(255, 100, 100, 100),
              ),
            ),
          ),
          Positioned(
            // 現在地に移動するボタン
            bottom: 20,
            right: 15,
            child: FloatingActionButton(
              heroTag: null, // Heroアニメーションを無効にする
              shape: const CircleBorder(),
              onPressed: () {
                ref.read(mapScreenProvider.notifier).getCurrentLocation();
              },
              //backgroundColor: //Colors.white,
              child: const Icon(
                Icons.my_location,
                size: 27.5,
                //color: Color.fromARGB(255, 100, 100, 100),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// TODO: ウィンドウ埋めた後のロジック
// TODO: 出発する空港をピンor円の内部の空港で指定する。 (円内部の空港→画面中心の座標から半径300以内に位置する場所？)
// TODO: 出発する空港と行き先を指定したら、適切な経路や値段を表示する。
// TODO: GoogleMapを長押しでもピンを指して、目的地設定できるようにする。
// TODO: リファクタリング
// TODO: devブランチで作業し、終わったらmainブランチにマージする。
// gitの流れが参考になる(https://qiita.com/yukiyoshimura/items/7aa4a8f8db493ab97c2b)
