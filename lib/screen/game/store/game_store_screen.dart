// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class GameStoreScreen extends StatefulWidget {
//   const GameStoreScreen({super.key});
//
//   @override
//   State<GameStoreScreen> createState() => _GameStoreScreenState();
// }
//
// class _GameStoreScreenState extends State<GameStoreScreen>
//     with SingleTickerProviderStateMixin {
//   static const Color _purple = Color(0xFF8B78FF);
//   static const Color _purpleDeep = Color(0xFF5745DB);
//   static const Color _gold = Color(0xFFFFC857);
//   static const Color _green = Color(0xFF37D99A);
//   static const Color _red = Color(0xFFFF657A);
//   static const Color _orange = Color(0xFFFFAD55);
//   static const Color _blue = Color(0xFF5DA9FF);
//
//   static const Color _darkBg = Color(0xFF0B0D18);
//   static const Color _darkCard = Color(0xFF151827);
//   static const Color _darkBorder = Color(0xFF252940);
//   static const Color _lightBg = Color(0xFFF5F6FC);
//   static const Color _lightBorder = Color(0xFFE9EAF4);
//
//   late final TabController _tabs;
//
//   bool get _isDark => Theme.of(context).brightness == Brightness.dark;
//
//   Color get _bg => _isDark ? _darkBg : _lightBg;
//
//   Color get _card => _isDark ? _darkCard : Colors.white;
//
//   Color get _border => _isDark ? _darkBorder : _lightBorder;
//
//   Color get _primary =>
//       _isDark ? const Color(0xFFF5F5FF) : const Color(0xFF202139);
//
//   Color get _secondary =>
//       _isDark ? const Color(0xFF999DB8) : const Color(0xFF797D96);
//
//   @override
//   void initState() {
//     super.initState();
//     _tabs = TabController(length: 3, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     _tabs.dispose();
//     super.dispose();
//   }
//
//   void _showPreviewMessage(String title, String action) {
//     Get.snackbar(
//       action == 'Buy' ? 'Purchase Preview' : 'Rewarded Ad Preview',
//       action == 'Buy'
//           ? '$title purchase will be available when coin spending is connected.'
//           : 'Rewarded ads for $title will be available when AdMob is connected.',
//       snackPosition: SnackPosition.BOTTOM,
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(16),
//       backgroundColor: _card,
//       colorText: _primary,
//       borderRadius: 18,
//       duration: const Duration(seconds: 2),
//       icon: Icon(
//         action == 'Buy'
//             ? Icons.shopping_bag_rounded
//             : Icons.play_circle_fill_rounded,
//         color: action == 'Buy' ? _purple : _green,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _bg,
//       body: Stack(
//         children: [
//           Positioned(
//             top: -130,
//             right: -110,
//             child: IgnorePointer(
//               child: Container(
//                 width: 300,
//                 height: 300,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: _purple.withValues(alpha: 0.07),
//                 ),
//               ),
//             ),
//           ),
//           SafeArea(
//             child: Column(
//               children: [
//                 _buildHeader(),
//                 Expanded(
//                   child: CustomScrollView(
//                     physics: const BouncingScrollPhysics(),
//                     slivers: [
//                       SliverToBoxAdapter(
//                         child: Padding(
//                           padding: const EdgeInsets.fromLTRB(15, 8, 15, 25),
//                           child: _buildHero(),
//                         ),
//                       ),
//                       SliverToBoxAdapter(
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 15),
//                           child: _buildSectionHeading(),
//                         ),
//                       ),
//                       SliverToBoxAdapter(
//                         child: Padding(
//                           padding: const EdgeInsets.fromLTRB(15, 17, 15, 18),
//                           child: _buildTabs(),
//                         ),
//                       ),
//                       SliverPadding(
//                         padding: const EdgeInsets.symmetric(horizontal: 15),
//                         sliver: SliverToBoxAdapter(
//                           child: AnimatedBuilder(
//                             animation: _tabs,
//                             builder: (context, _) {
//                               return AnimatedSwitcher(
//                                 duration: const Duration(milliseconds: 250),
//                                 switchInCurve: Curves.easeOutCubic,
//                                 switchOutCurve: Curves.easeInCubic,
//                                 transitionBuilder: (child, animation) {
//                                   return FadeTransition(
//                                     opacity: animation,
//                                     child: SlideTransition(
//                                       position: Tween<Offset>(
//                                         begin: const Offset(0, 0.025),
//                                         end: Offset.zero,
//                                       ).animate(animation),
//                                       child: child,
//                                     ),
//                                   );
//                                 },
//                                 child: KeyedSubtree(
//                                   key: ValueKey(_tabs.index),
//                                   child: _buildStoreItems(),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ),
//                       SliverToBoxAdapter(
//                         child: Padding(
//                           padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
//                           child: _buildFooter(),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // HEADER
//
//   Widget _buildHeader() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
//       child: Row(
//         children: [
//           _roundButton(
//             icon: Icons.arrow_back_rounded,
//             onTap: () => Get.back(),
//           ),
//           const SizedBox(width: 13),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Game Store',
//                   style: TextStyle(
//                     color: _primary,
//                     fontSize: 21,
//                     fontWeight: FontWeight.w900,
//                     letterSpacing: -0.7,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   'Upgrade your adventure',
//                   style: TextStyle(
//                     color: _secondary,
//                     fontSize: 11.5,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Coin balance UI only
//           Container(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 11,
//               vertical: 9,
//             ),
//             decoration: BoxDecoration(
//               color: _card,
//               borderRadius: BorderRadius.circular(15),
//               border: Border.all(color: _border),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(
//                   Icons.monetization_on_rounded,
//                   color: _gold,
//                   size: 19,
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   '250',
//                   style: TextStyle(
//                     color: _primary,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w900,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
//     return Material(
//       color: _card,
//       shape: const CircleBorder(),
//       child: InkWell(
//         customBorder: const CircleBorder(),
//         onTap: onTap,
//         child: Container(
//           width: 43,
//           height: 43,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             border: Border.all(color: _border),
//           ),
//           child: Icon(icon, size: 21, color: _primary),
//         ),
//       ),
//     );
//   }
//
//   // HERO
//
//   Widget _buildHero() {
//     return Container(
//       height: 205,
//       clipBehavior: Clip.antiAlias,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(27),
//         gradient: const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Color(0xFF211A4B), Color(0xFF43349C), Color(0xFF6C54E8)],
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: _purple.withValues(alpha: 0.16),
//             blurRadius: 30,
//             offset: const Offset(0, 12),
//           ),
//         ],
//       ),
//       child: Stack(
//         children: [
//           Positioned(
//             right: -40,
//             top: -75,
//             child: Container(
//               width: 230,
//               height: 230,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(
//                   color: Colors.white.withValues(alpha: 0.07),
//                   width: 28,
//                 ),
//               ),
//             ),
//           ),
//           Positioned(
//             right: 3,
//             bottom: -36,
//             child: Container(
//               width: 160,
//               height: 160,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Colors.white.withValues(alpha: 0.045),
//               ),
//             ),
//           ),
//           Positioned(
//             right: 17,
//             top: 43,
//             child: Transform.rotate(
//               angle: -0.14,
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   Icon(
//                     Icons.monetization_on_rounded,
//                     size: 115,
//                     color: _gold.withValues(alpha: 0.13),
//                   ),
//                   const Icon(
//                     Icons.monetization_on_rounded,
//                     size: 88,
//                     color: _gold,
//                   ),
//                   const Positioned(
//                     top: 20,
//                     right: 21,
//                     child: Icon(
//                       Icons.auto_awesome_rounded,
//                       color: Colors.white,
//                       size: 19,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Positioned(
//             right: 105,
//             top: 32,
//             child: Icon(
//               Icons.star_rounded,
//               size: 19,
//               color: _gold.withValues(alpha: 0.8),
//             ),
//           ),
//           Positioned(
//             right: 24,
//             bottom: 25,
//             child: Icon(
//               Icons.auto_awesome_rounded,
//               size: 22,
//               color: Colors.white.withValues(alpha: 0.8),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(21, 21, 15, 18),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 7,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withValues(alpha: 0.11),
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(
//                       color: Colors.white.withValues(alpha: 0.13),
//                     ),
//                   ),
//                   child: const Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         Icons.workspace_premium_rounded,
//                         size: 13,
//                         color: _gold,
//                       ),
//                       SizedBox(width: 6),
//                       Text(
//                         'THE ADVENTURER\'S SHOP',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 8.5,
//                           fontWeight: FontWeight.w900,
//                           letterSpacing: 1,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//                 const Text(
//                   'Make every\nmove count.',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 27,
//                     height: 1.12,
//                     fontWeight: FontWeight.w900,
//                     letterSpacing: -0.9,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Your next advantage starts here.',
//                   style: TextStyle(
//                     color: Colors.white.withValues(alpha: 0.72),
//                     fontSize: 11,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const Spacer(),
//                 Row(
//                   children: [
//                     _heroTag(Icons.monetization_on_rounded, 'COINS', _gold),
//                     const SizedBox(width: 7),
//                     _heroTag(Icons.favorite_rounded, 'LIVES', _red),
//                     const SizedBox(width: 7),
//                     _heroTag(Icons.timer_rounded, 'TIME', _green),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _heroTag(IconData icon, String text, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.white.withValues(alpha: 0.10),
//         borderRadius: BorderRadius.circular(9),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 12, color: color),
//           const SizedBox(width: 5),
//           Text(
//             text,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 8,
//               fontWeight: FontWeight.w900,
//               letterSpacing: 0.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // SECTION HEADING
//
//   Widget _buildSectionHeading() {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Explore the store',
//                 style: TextStyle(
//                   color: _primary,
//                   fontSize: 19,
//                   fontWeight: FontWeight.w900,
//                   letterSpacing: -0.55,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 'Choose your next power-up.',
//                 style: TextStyle(color: _secondary, fontSize: 11.5),
//               ),
//             ],
//           ),
//         ),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
//           decoration: BoxDecoration(
//             color: _purple.withValues(alpha: 0.09),
//             borderRadius: BorderRadius.circular(9),
//           ),
//           child: const Text(
//             '3 CATEGORIES',
//             style: TextStyle(
//               color: _purple,
//               fontSize: 8.5,
//               fontWeight: FontWeight.w900,
//               letterSpacing: 0.7,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // TABS
//
//   Widget _buildTabs() {
//     return Container(
//       height: 55,
//       padding: const EdgeInsets.all(5),
//       decoration: BoxDecoration(
//         color: _card,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: _border),
//       ),
//       child: TabBar(
//         controller: _tabs,
//         isScrollable: false,
//         dividerColor: Colors.transparent,
//         indicatorSize: TabBarIndicatorSize.tab,
//         splashBorderRadius: BorderRadius.circular(13),
//         indicator: BoxDecoration(
//           gradient: const LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [_purple, _purpleDeep],
//           ),
//           borderRadius: BorderRadius.circular(13),
//           boxShadow: [
//             BoxShadow(
//               color: _purple.withValues(alpha: 0.22),
//               blurRadius: 9,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         labelColor: Colors.white,
//         unselectedLabelColor: _secondary,
//         labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
//         unselectedLabelStyle: const TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.w700,
//         ),
//         tabs: const [
//           Tab(text: 'Coins'),
//           Tab(text: 'Lives'),
//           Tab(text: 'Time'),
//         ],
//       ),
//     );
//   }
//
//   // PRODUCTS
//
//   Widget _buildStoreItems() {
//     switch (_tabs.index) {
//       case 1:
//         return _buildLivesItems();
//       case 2:
//         return _buildTimeItems();
//       default:
//         return _buildCoinItems();
//     }
//   }
//
//   Widget _buildCoinItems() {
//     return _buildProductList([
//       _StoreItemData(
//         title: 'Coin Mini',
//         description: 'A small boost to get started.',
//         amount: '100',
//         unit: 'COINS',
//         icon: Icons.monetization_on_rounded,
//         color: _gold,
//         adsRequired: 2,
//         badge: 'STARTER',
//       ),
//       _StoreItemData(
//         title: 'Coin Plus',
//         description: 'A little extra for your journey.',
//         amount: '200',
//         unit: 'COINS',
//         icon: Icons.paid_rounded,
//         color: _orange,
//         adsRequired: 5,
//       ),
//       _StoreItemData(
//         title: 'Coin Boost',
//         description: 'More coins for more possibilities.',
//         amount: '500',
//         unit: 'COINS',
//         icon: Icons.savings_rounded,
//         color: _purple,
//         adsRequired: 7,
//         badge: 'POPULAR',
//         featured: true,
//       ),
//       _StoreItemData(
//         title: 'Coin Vault',
//         description: 'A bigger stash for your adventure.',
//         amount: '1,000',
//         unit: 'COINS',
//         icon: Icons.diamond_rounded,
//         color: _gold,
//         adsRequired: 12,
//         badge: 'BIG BOOST',
//       ),
//     ]);
//   }
//
//   Widget _buildLivesItems() {
//     return _buildProductList([
//       _StoreItemData(
//         title: 'Extra Life',
//         description: 'One more chance at the maze.',
//         amount: '+1',
//         unit: 'LIFE',
//         icon: Icons.favorite_rounded,
//         color: _red,
//         coinPrice: 100,
//         badge: 'QUICK BOOST',
//       ),
//       _StoreItemData(
//         title: 'Double Chance',
//         description: 'Keep going with an extra chance.',
//         amount: '+2',
//         unit: 'LIVES',
//         icon: Icons.favorite_rounded,
//         color: _red,
//         coinPrice: 180,
//         badge: 'POPULAR',
//         featured: true,
//       ),
//       _StoreItemData(
//         title: 'Life Saver',
//         description: 'Extra chances for tricky levels.',
//         amount: '+3',
//         unit: 'LIVES',
//         icon: Icons.health_and_safety_rounded,
//         color: _green,
//         coinPrice: 250,
//       ),
//     ]);
//   }
//
//   Widget _buildTimeItems() {
//     return _buildProductList([
//       _StoreItemData(
//         title: 'Quick Time',
//         description: 'A little more time to think.',
//         amount: '+15',
//         unit: 'SECONDS',
//         icon: Icons.timer_rounded,
//         color: _orange,
//         coinPrice: 75,
//         badge: 'QUICK BOOST',
//       ),
//       _StoreItemData(
//         title: 'Time Plus',
//         description: 'Take a moment to plan ahead.',
//         amount: '+30',
//         unit: 'SECONDS',
//         icon: Icons.hourglass_bottom_rounded,
//         color: _orange,
//         coinPrice: 125,
//         badge: 'POPULAR',
//         featured: true,
//       ),
//       _StoreItemData(
//         title: 'Time Boost',
//         description: 'More time for tougher puzzles.',
//         amount: '+60',
//         unit: 'SECONDS',
//         icon: Icons.av_timer_rounded,
//         color: _green,
//         coinPrice: 200,
//       ),
//       _StoreItemData(
//         title: 'Time Master',
//         description: 'A generous boost for your run.',
//         amount: '+90',
//         unit: 'SECONDS',
//         icon: Icons.speed_rounded,
//         color: _blue,
//         coinPrice: 275,
//         badge: 'BIG BOOST',
//       ),
//     ]);
//   }
//
//   // VERTICAL PRODUCT LIST
//
//   Widget _buildProductList(List<_StoreItemData> items) {
//     return Column(
//       children: [
//         for (int index = 0; index < items.length; index++) ...[
//           _storeItem(items[index]),
//           if (index != items.length - 1) const SizedBox(height: 12),
//         ],
//       ],
//     );
//   }
//
//   Widget _storeItem(_StoreItemData item) {
//     final bool isCoinPack = item.adsRequired != null;
//
//     // Lives and Time display their coin price on the Buy button.
//     // Coin packs keep the original Buy label.
//     final String buyLabel = isCoinPack ? 'Buy' : '${item.coinPrice}';
//
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: _card,
//         borderRadius: BorderRadius.circular(22),
//         border: Border.all(
//           color: _border,
//           width: 1,
//         ),
//         boxShadow: [
//           if (!_isDark)
//             BoxShadow(
//               color: const Color(0xFF25264A).withValues(alpha: 0.025),
//               blurRadius: 14,
//               offset: const Offset(0, 5),
//             ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 57,
//                 height: 61,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [
//                       item.color.withValues(alpha: 0.20),
//                       item.color.withValues(alpha: 0.065),
//                     ],
//                   ),
//                   borderRadius: BorderRadius.circular(17),
//                   border: Border.all(
//                     color: item.color.withValues(alpha: 0.13),
//                   ),
//                 ),
//                 child: Icon(
//                   item.icon,
//                   color: item.color,
//                   size: 30,
//                 ),
//               ),
//               const SizedBox(width: 13),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       item.title,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         color: _primary,
//                         fontSize: 13.5,
//                         fontWeight: FontWeight.w900,
//                         letterSpacing: -0.25,
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     Text(
//                       item.description,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         color: _secondary,
//                         fontSize: 10.5,
//                         height: 1.4,
//                       ),
//                     ),
//                     const SizedBox(height: 7),
//                     Row(
//                       children: [
//                         Text(
//                           item.amount,
//                           style: TextStyle(
//                             color: item.color,
//                             fontSize: 20,
//                             fontWeight: FontWeight.w900,
//                             letterSpacing: -0.5,
//                           ),
//                         ),
//                         const SizedBox(width: 6),
//                         Flexible(
//                           child: Text(
//                             item.unit,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                               color: _secondary,
//                               fontSize: 8.5,
//                               fontWeight: FontWeight.w900,
//                               letterSpacing: 0.45,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               if (item.badge != null) ...[
//                 const SizedBox(width: 6),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 7,
//                     vertical: 5,
//                   ),
//                   decoration: BoxDecoration(
//                     color: item.color.withValues(alpha: 0.10),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     item.badge!,
//                     style: TextStyle(
//                       color: item.color,
//                       fontSize: 7,
//                       fontWeight: FontWeight.w900,
//                       letterSpacing: 0.15,
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//
//           // Only coin packs show the rewarded-ad information row.
//           if (isCoinPack) ...[
//             const SizedBox(height: 13),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 11,
//                 vertical: 9,
//               ),
//               decoration: BoxDecoration(
//                 color: _gold.withValues(
//                   alpha: _isDark ? 0.10 : 0.08,
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: _gold.withValues(alpha: 0.14),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(
//                     Icons.play_circle_fill_rounded,
//                     size: 17,
//                     color: _gold,
//                   ),
//                   const SizedBox(width: 7),
//                   Expanded(
//                     child: Text(
//                       '${item.adsRequired} rewarded ads to earn '
//                           '${item.amount} coins',
//                       style: TextStyle(
//                         color: _primary,
//                         fontSize: 10.5,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 12),
//           ] else
//             const SizedBox(height: 13),
//
//           Row(
//             children: [
//               Expanded(
//                 child: _actionButton(
//                   label: buyLabel,
//                   icon: isCoinPack
//                       ? Icons.shopping_bag_rounded
//                       : Icons.monetization_on_rounded,
//                   color: _purple,
//                   filled: true,
//                   onTap: () => _showPreviewMessage(item.title, 'Buy'),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: _actionButton(
//                   label: isCoinPack
//                       ? 'Watch Ad (${item.adsRequired})'
//                       : 'Watch Ad',
//                   icon: Icons.play_circle_fill_rounded,
//                   color: _green,
//                   filled: false,
//                   onTap: () => _showPreviewMessage(
//                     item.title,
//                     'Watch Ad',
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _actionButton({
//     required String label,
//     required IconData icon,
//     required Color color,
//     required bool filled,
//     required VoidCallback onTap,
//   }) {
//     return SizedBox(
//       height: 43,
//       child: Material(
//         color: filled ? color : color.withValues(alpha: _isDark ? 0.12 : 0.09),
//         borderRadius: BorderRadius.circular(13),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(13),
//           onTap: onTap,
//           child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(13),
//               border: Border.all(
//                 color: filled ? color : color.withValues(alpha: 0.25),
//               ),
//               boxShadow: [
//                 if (filled)
//                   BoxShadow(
//                     color: color.withValues(alpha: 0.16),
//                     blurRadius: 10,
//                     offset: const Offset(0, 3),
//                   ),
//               ],
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(icon, color: filled ? Colors.white : color, size: 16),
//                 const SizedBox(width: 6),
//                 Flexible(
//                   child: Text(
//                     label,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       color: filled ? Colors.white : color,
//                       fontSize: 10.5,
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // FOOTER
//
//   Widget _buildFooter() {
//     return Container(
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: _card,
//         borderRadius: BorderRadius.circular(19),
//         border: Border.all(color: _border),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 34,
//             height: 34,
//             decoration: BoxDecoration(
//               color: _blue.withValues(alpha: 0.11),
//               borderRadius: BorderRadius.circular(11),
//             ),
//             child: const Icon(
//               Icons.info_outline_rounded,
//               color: _blue,
//               size: 19,
//             ),
//           ),
//           const SizedBox(width: 11),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Your adventure, your way',
//                   style: TextStyle(
//                     color: _primary,
//                     fontSize: 11.5,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   'Prices are configurable. Coin spending, rewards, '
//                   'and rewarded ads must be connected before '
//                   'these buttons grant items.',
//                   style: TextStyle(
//                     color: _secondary,
//                     fontSize: 10.5,
//                     height: 1.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _StoreItemData {
//   final String title;
//   final String description;
//   final String amount;
//   final String unit;
//   final IconData icon;
//   final Color color;
//   final String? badge;
//   final bool featured;
//
//   // For coin packs, number of rewarded ads needed.
//   final int? adsRequired;
//
//   // For lives and time, the in-game coin price.
//   final int? coinPrice;
//
//   const _StoreItemData({
//     required this.title,
//     required this.description,
//     required this.amount,
//     required this.unit,
//     required this.icon,
//     required this.color,
//     this.badge,
//     this.featured = false,
//     this.adsRequired,
//     this.coinPrice,
//   });
// }
