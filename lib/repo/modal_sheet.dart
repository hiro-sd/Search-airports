import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticket_app/riverpod/map_screen_state_notifier.dart';

// BottomSheetを表示する関数
void showCustomBottomSheet(BuildContext context, WidgetRef ref, String? tmp,
    String placeName, List<String> photoUrls) {
  final state = ref.watch(mapScreenProvider);
  showModalBottomSheet(
    // ignore: use_build_context_synchronously
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    barrierColor: Colors.black.withOpacity(0.2),
    builder: (context) {
      return FractionallySizedBox(
          heightFactor: 0.7,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  tmp == 'tmpTakeoff'
                      ? AppLocalizations.of(context)!.set_departure
                      : tmp == 'tmpLand'
                          ? AppLocalizations.of(context)!.set_destination
                          : AppLocalizations.of(context)!.set_location,
                  style: const TextStyle(fontSize: 15),
                ),
                Text(
                  placeName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (photoUrls.isNotEmpty)
                  SizedBox(
                    height: 400,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                      ),
                      itemCount: photoUrls.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          photoUrls[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Text(AppLocalizations.of(context)!
                                .failed_to_load_image);
                          },
                        );
                      },
                    ),
                  )
                else
                  Text(AppLocalizations.of(context)!.no_photo), // 写真がない場合の表示
                tmp == 'tmpTakeoff' ||
                        tmp ==
                            'tmpLand' // tmpTakeoffかtmpLandの場合(ウィンドウをから検索した場合)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context); // BottomSheetを閉じる
                              },
                              child: Text(
                                AppLocalizations.of(context)!.cancel,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (tmp == 'tmpTakeoff') {
                                  ref
                                      .read(mapScreenProvider.notifier)
                                      .updateselectedDeparture(placeName);
                                  state.tmpTakeoff
                                      ? null
                                      : ref
                                          .read(mapScreenProvider.notifier)
                                          .toggleTmpTakeoff();
                                } else if (tmp == 'tmpLand') {
                                  ref
                                      .read(mapScreenProvider.notifier)
                                      .updateSelectedDestination(placeName);
                                  state.tmpLand
                                      ? null
                                      : ref
                                          .read(mapScreenProvider.notifier)
                                          .toggleTmpLand();
                                }
                                Navigator.pop(context); // BottomSheetを閉じる
                              },
                              child:
                                  Text(AppLocalizations.of(context)!.confirm),
                            ),
                          ])
                    : Row(
                        // tmpTakeoffでもtmpLandでもない場合(Markerをクリックした場合)
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15)),
                              onPressed: () {
                                ref
                                    .read(mapScreenProvider.notifier)
                                    .updateselectedDeparture(
                                      placeName,
                                    );
                                if (!state.tmpTakeoff) {
                                  ref
                                      .read(mapScreenProvider.notifier)
                                      .toggleTmpTakeoff();
                                }
                                Navigator.pop(context);
                              },
                              child: Text(
                                  AppLocalizations.of(context)!.departure)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15)),
                            onPressed: () {
                              Navigator.pop(context); // BottomSheetを閉じる
                            },
                            child: Text(
                              AppLocalizations.of(context)!.cancel,
                            ),
                          ),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15)),
                              onPressed: () {
                                ref
                                    .read(mapScreenProvider.notifier)
                                    .updateSelectedDestination(
                                      placeName,
                                    );
                                if (!state.tmpLand) {
                                  ref
                                      .read(mapScreenProvider.notifier)
                                      .toggleTmpLand();
                                }
                                Navigator.pop(context); // BottomSheetを閉じる
                              },
                              child: Text(
                                  AppLocalizations.of(context)!.destination)),
                        ],
                      ),
              ],
            ),
          ));
    },
  );
}
