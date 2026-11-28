// GENERATED from the owner's twelve maze boards (the art in
// assets/games/maze). Each board's walls were read off its picture, then
// checked: one route between any two cells, every cell reachable, and a way
// from the start to the exit. `open` has one hex digit per cell, row by row:
// bit 0 up, 1 right, 2 down, 3 left (1 means the way is open). The rows are
// written one per line and join into one string.

class MazeBoard {
  const MazeBoard({
    required this.asset,
    required this.size,
    required this.imageSize,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.open,
  });

  final String asset;

  /// Cells along each side.
  final int size;

  /// The picture is square, [imageSize] pixels a side.
  final int imageSize;

  /// Where the maze floor sits inside the picture, in pixels.
  final int left, right, top, bottom;

  /// One hex digit per cell, row by row ([size] x [size] characters).
  final String open;

  /// Centre of cell ([row], [col]) as a fraction of the picture (0 to 1).
  (double, double) centre(int row, int col) {
    final double cw = (right - left) / size, ch = (bottom - top) / size;
    return (
      (left + (col + 0.5) * cw) / imageSize,
      (top + (row + 0.5) * ch) / imageSize,
    );
  }

  /// Width and height of one cell as a fraction of the picture.
  (double, double) get cell =>
      ((right - left) / size / imageSize, (bottom - top) / size / imageSize);
}

const List<MazeBoard> kMazeBoards = <MazeBoard>[
  MazeBoard(
    asset: 'assets/games/maze/maze_05.webp',
    size: 5,
    imageSize: 650,
    left: 75,
    right: 575,
    top: 88,
    bottom: 565,
    open:
      '2ac2c'
      '6856d'
      '7a951'
      '3ac3c'
      '2aba9',
  ),
  MazeBoard(
    asset: 'assets/games/maze/maze_06.webp',
    size: 6,
    imageSize: 650,
    left: 75,
    right: 575,
    top: 88,
    bottom: 565,
    open:
      '42aeac'
      '3ac569'
      '6a953c'
      '52e945'
      '569695'
      '392ba9',
  ),
  MazeBoard(
    asset: 'assets/games/maze/maze_08.webp',
    size: 8,
    imageSize: 650,
    left: 75,
    right: 575,
    top: 88,
    bottom: 565,
    open:
      '42aaeaac'
      '3aaa96c5'
      '6ac6a939'
      '3c396c6c'
      '456a9395'
      '79386ac5'
      '3c6c3c3d'
      '2b93a929',
  ),
  MazeBoard(
    asset: 'assets/games/maze/maze_09.webp',
    size: 9,
    imageSize: 650,
    left: 75,
    right: 575,
    top: 88,
    bottom: 565,
    open:
      '2c6aac6ac'
      '693c457c5'
      '56a979155'
      '392c3c695'
      '6c6b83969'
      '5396ac694'
      '7ac3c392d'
      '3c3c3c6c5'
      '2b83ab939',
  ),
  MazeBoard(
    asset: 'assets/games/maze/maze_11.webp',
    size: 11,
    imageSize: 650,
    left: 75,
    right: 575,
    top: 88,
    bottom: 565,
    open:
      '2c2eaaae86c'
      '43c56ac5695'
      '7a951693b85'
      '3c43c56c6ad'
      '45783d53969'
      '553ae93c694'
      '796c56853ad'
      '56953d69685'
      '552bc152bc5'
      '53ac3a96a95'
      '3aa92aabaa9',
  ),
  MazeBoard(
    asset: 'assets/games/maze/maze_12.webp',
    size: 12,
    imageSize: 650,
    left: 75,
    right: 575,
    top: 88,
    bottom: 565,
    open:
      '42aaec6aaaac'
      '56ac5396ac45'
      '55693aad2b95'
      '5556ac456aad'
      '5539455556a9'
      '57c6d53d53ac'
      '55513bc17ac5'
      '513aec3c5695'
      '56ac15691545'
      '39456952e93d'
      '6a93943c3ac5'
      '3aaaababaa91',
  ),
  MazeBoard(
    asset: 'assets/games/maze/maze_14.webp',
    size: 14,
    imageSize: 700,
    left: 80,
    right: 619,
    top: 94,
    bottom: 608,
    open:
      '42eaaeaaaa86e8'
      '3c7a83aaec693c'
      '4516aaac13bc6d'
      '53c3c683ac2955'
      '7c5693ec456a95'
      '51396a95553ec5'
      '7e86d2af93c555'
      '53a956c16c5151'
      '52e8393a953c7c'
      '3c3eac6c6bc515'
      '43a943955293ad'
      '7aaabaa93aaaa9'
      '3ac6c6ac6aac6c'
      '2ab9392b92ab91',
  ),
  MazeBoard(
    asset: 'assets/games/maze/maze_16.webp',
    size: 16,
    imageSize: 700,
    left: 80,
    right: 619,
    top: 94,
    bottom: 608,
    open:
      '46c6aaaaac6aaaac'
      '393946aaa93a86ad'
      '6aac556aaaaac545'
      '3c695552aea85539'
      '693a9556c7aa93ac'
      '56aac57953c2eac5'
      '556c3916d2bc3c55'
      '53956ac516c3a955'
      '7ac39453c556a855'
      '52bac7969557c695'
      '56ac53c3c5515569'
      '55693c3c793c553c'
      '5556a9693ac53bad'
      '55538696c693ec69'
      '553aa92d516c1554'
      '3baaaaa93a93a939',
  ),
  MazeBoard(
    asset: 'assets/games/maze/maze_18.webp',
    size: 18,
    imageSize: 700,
    left: 80,
    right: 619,
    top: 94,
    bottom: 608,
    open:
      '42ec2aaaeaac6c2aec'
      '3a93c6aa96a953ac55'
      '6aaa956c452abc4551'
      '52ec695553c6c5793c'
      '3a939693bc55393c6d'
      '6a86abaac1556c2b95'
      '3ac56c6c3a9397ac69'
      '6a939553ac6ac3c554'
      '56ec4396c39692953d'
      '395396e956c52ea969'
      '6a96a952d539696c54'
      '56a9683c1546bc1555'
      '5546bac3a97945693d'
      '793b86bc2aba957e85'
      '3aaac3c3ac6c6953c5'
      '6ae83c56c5553c5439'
      '543c69395553c53bc4'
      '3b83baaa9392b92ab9',
  ),
  MazeBoard(
    asset: 'assets/games/maze/maze_20.webp',
    size: 20,
    imageSize: 700,
    left: 80,
    right: 619,
    top: 94,
    bottom: 608,
    open:
      '46c6aac6ac6c6c6aaeac'
      '39396a97c1539396c3c5'
      '6c6a96c17aba86a93a95'
      '5396a93c546aa946e869'
      '3ac7ac45553c46b93a94'
      '469385553bc5556aaec5'
      '796c693bc455793e853d'
      '3c5396ac53d53ac1692d'
      '697c6b853c53c43c3ac5'
      '52d396a9697857a96a95'
      '3c3a87c45696952afc45'
      '43c6c157956943ac1539'
      '3c393a93c552fc43c7ac'
      '696e86aa913c53d69169'
      '7a93a92ec6a97c13ac7c'
      '3ac2eea9396c53ee8555'
      '6c3c556ea85394516915'
      '53a915516c3c6d3c3ac5'
      '3aaaa97a978395696a95'
      '2aaaaaba83aaa93abaa9',
  ),
  MazeBoard(
    asset: 'assets/games/maze/maze_23.webp',
    size: 23,
    imageSize: 700,
    left: 80,
    right: 619,
    top: 94,
    bottom: 608,
    open:
      '2c6aec6aaaaaaaaac6c6aac'
      '455453946aaac6e83939685'
      '555552abd6c4553e86aad69'
      '793d3aac553d53c3a96c554'
      '52e92c6939697856ac5553d'
      '3c3aa956c43c56916d53969'
      '43c6c6953f85392e953ac3c'
      '78393947c1692ea9456c3c5'
      '7c6aaad53a96a9687917c55'
      '13be86d3ac696abc3ac1539'
      '6ac1693c457c16aba83c7ac'
      '52bc56c55553c56aaaa93c1'
      '7c4555539538553c6c2ec3c'
      '553b953ac3c6978553a93ad'
      '53ac696c3a956ba97c2aec5'
      '3c4396916ea93c2e93ac539'
      '43bc6bac556ac3c56e853c4'
      '786938695552d453916943d'
      '7c3aac7a957c793c6c3c569'
      '17ac693a855556c39569794'
      '6d293aaaa9551556a95452d'
      '516ac6aea8556953aa953c5'
      '3ab83b83aa93b83aaaabab9',
  ),
  MazeBoard(
    asset: 'assets/games/maze/maze_26.webp',
    size: 26,
    imageSize: 700,
    left: 80,
    right: 619,
    top: 94,
    bottom: 608,
    open:
      '2aac6ea86aac6c6aaaaaaaaae8'
      '46a9516aba8395786c6aaaac7c'
      '552abab86c6ea956953c686955'
      '53aaaaaa95556a9569693c5295'
      '7ec6aaea855154693c7c6956ad'
      '5513ac3aa97ab956a9153ab945'
      '556ac56c2c52c693c6c3ec6ab9'
      '53b853956956d3c2b93c153ac4'
      '546ad6857c555456c2ad696855'
      '3d56b96953b93d3956c396ba95'
      '69516a9456aac16c393ac3c2ed'
      '3c3a92eb956c3c53aaaa943c15'
      '452aec56c553c3946aaaad696d'
      '53aa9515397c3c2d56ac4556d1'
      '7c2e83c7c2d543ad554553913c'
      '57a96a913c557e8539557ac6ad'
      '516a96ac691553a96ed5569529'
      '7c52ed4396a93a869515552bec'
      '153c55786bac6ac543a953ac15'
      '6d69557a96c394397c6a92aba9'
      '51545552a93aed6c5396aaaaac'
      '7a93d53c6ac6939396c56a86ad'
      '3aac13c53c53eaaaa95796a945'
      '6ac56a95693c3aaaa8396946b9'
      '3c393ac396856aaaaaac3c796c'
      '2baaaa92abab92aaaaaba93a91',
  ),
];
