// The maze boards (the art in assets/games/maze). Twelve are the owner's
// own pictures, with the walls read off each; twelve more are drawn on the
// owner's empty framed board from mazes made for it. Every board was
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
    asset: 'assets/games/maze/maze_07.webp',
    size: 7,
    imageSize: 700,
    left: 104,
    right: 595,
    top: 107,
    bottom: 598,
    open:
      '2ac6aac'
      '4693e85'
      '53ac169'
      '3e83c3c'
      '696c3ad'
      '5693e85'
      '3ba83a9',
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
    asset: 'assets/games/maze/maze_10.webp',
    size: 10,
    imageSize: 700,
    left: 104,
    right: 595,
    top: 107,
    bottom: 598,
    open:
      '2ac46c6ae8'
      '6c5393b87c'
      '5556c6ac15'
      '553939696d'
      '53aaac56d5'
      '7aac295555'
      '3ac56a9155'
      '6c5396aa95'
      '553c696869'
      '13ab92bab8',
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
    asset: 'assets/games/maze/maze_13.webp',
    size: 13,
    imageSize: 700,
    left: 104,
    right: 595,
    top: 107,
    bottom: 598,
    open:
      '46aac2ac6aeac'
      '53c456a954529'
      '3c53d56c553ac'
      '693c5793bbc69'
      '52e95786ac13c'
      '3a969169696c5'
      '6ac3aa943c539'
      '7c56aaabc556c'
      '15556aac55555'
      '691552e939555'
      '3ac57c52aab95'
      '6a951556c6aad'
      '3aaba939392a9',
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
    asset: 'assets/games/maze/maze_15.webp',
    size: 15,
    imageSize: 700,
    left: 104,
    right: 595,
    top: 107,
    bottom: 598,
    open:
      '2c6ae86aaaeaac4'
      '457c1696c696c55'
      '7953a9691529555'
      '543ac2bc696ad55'
      '578696ad5692955'
      '57a9694557c6a95'
      '53aa94795153aad'
      '3c6ac79456bc685'
      '695457a9552d569'
      '56b9396a97c3954'
      '556aac52c53aa95'
      '5552c556956eac5'
      '517c7955691543d'
      '3c1552d796a97a9'
      '2ba93a93a92aba8',
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
    asset: 'assets/games/maze/maze_17.webp',
    size: 17,
    imageSize: 700,
    left: 104,
    right: 595,
    top: 107,
    bottom: 598,
    open:
      '42aec6aeac6ac2aec'
      '56a95169457c3aa95'
      '396a9696d513c6aa9'
      '6a92e969556a956a8'
      '52ea92bc5394693ec'
      '3a96ac2d7c2d3ac55'
      '6c2d43c153abc4555'
      '53a97c3c52aabd555'
      '7aac556956ac29515'
      '5685539693c3aa969'
      '79693aad6a92eaabc'
      '1696c6853aac16c69'
      '6d6953c52e83a957c'
      '51543c3be96ee8555'
      '5693c3ac569516915'
      '53ac7c6913c5696c5'
      '3aab913aaa93ba939',
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
    asset: 'assets/games/maze/maze_19.webp',
    size: 19,
    imageSize: 700,
    left: 104,
    right: 595,
    top: 107,
    bottom: 598,
    open:
      '2c6c2aaaaec6c6aaaec'
      '4393aaaaa951396c695'
      '56c6c6aae856aa93945'
      '5539396ad693c6ac6d5'
      '556ac69293aa9545555'
      '553c556c6eaa8553939'
      '5569139393ac693aaac'
      '553eaaec2ac396aaac5'
      '53c38693ac7ac7c4695'
      '3c56a946a97c5553bad'
      '69396a956c55153ac45'
      '7c6c7aa95515696a979'
      '13d5546e93c53c52ab8'
      '6c1553956c53a97aaac'
      '53c53ac513baac3aa85'
      '56bb8697aaac43aaac5'
      '516ac52d6c697aae83d'
      '569453c1539452c3c69'
      '3ba93aba92abbab83b8',
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
    asset: 'assets/games/maze/maze_21.webp',
    size: 21,
    imageSize: 700,
    left: 104,
    right: 595,
    top: 107,
    bottom: 598,
    open:
      '2ac46aaaaaaaaaaaeac6c'
      '6a93baaac46aaaaa96955'
      '52aec2aab956aec2c3c55'
      '56a93ac6aa95453abc515'
      '3946ac396e83d56ac556d'
      '6ad56d6a93e853b855395'
      '5695513aac3a946ad16a9'
      '57853aae856c6d529696c'
      '55692ac3a9555156a9691'
      '513aaabaaa953c396abac'
      '3aeaac2aec43ad6c3ac69'
      '6a92c56c53d6c553c293c'
      '3c6a9393945555543c6ad'
      '693c6aaee9551553c3945'
      '7ac556c156b9697c7aad5'
      '5457953c3b8696953c455'
      '555783c3ac696b83c5395'
      '3d556c546954786a97c69'
      '695553953c555692a9554'
      '3c513aabc393956aaa955'
      '293aaaaabaaaa93aaaab9',
  ),
  MazeBoard(
    asset: 'assets/games/maze/maze_22.webp',
    size: 22,
    imageSize: 700,
    left: 104,
    right: 595,
    top: 107,
    bottom: 598,
    open:
      '2c6aac6aaaaeaea86eaaac'
      '6956c3b86ac5696a93c6c5'
      '3c393c6a94513ab86c3d55'
      '692aad52e93aaac693c155'
      '52eac53c3aaaaeb92eba95'
      '3a945783aec6c16ac786c5'
      '2ec7916ac53956b8556955'
      '69156c5693c4396a955695'
      '7ac39555687b8696a95569'
      '5456c3957c56a9296c5538'
      '55397ac51393ac6c5393ac'
      '53e83c156aac695556ae85'
      '3c3ec56956853ad555696d'
      '43a95396d7c3ac13d15695'
      '7ac692a9513ec3ac3a9529'
      '38556aaa96c538696ac3ac'
      '6c5396c6ed396a96bc3ac5'
      '53d46d15516c3c2bc56c3d'
      '7c3953a93c53c3ac5513e9'
      '156c3aac69543e8553ac54'
      '6957a8693a97c3a916c555'
      '3a93aabaaaa93aaaa93939',
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
    asset: 'assets/games/maze/maze_24.webp',
    size: 24,
    imageSize: 700,
    left: 104,
    right: 595,
    top: 107,
    bottom: 598,
    open:
      '2c6ec2c6aaec2ec2eaaac6ac'
      '45153c53c455693c7ac4556d'
      '556d2b96955396a93c555155'
      '79516aa96d3ac3aac553ba95'
      '547a96ac17c696aa913aac69'
      '53bac5456953c52eaaaaa93c'
      '3c6a9553945453c7c6aaac69'
      '693aa97a87b95451556e8394'
      '52eaac3ae96a953a95556aad'
      '3a96a96c5456c7ac695396ad'
      '2e83aa95395553c3943c4529'
      '696c6ac3aa953c56c78553ac'
      '7a953c786aa96d553d6956ad'
      '3c43a93a92c69557c152d545'
      '45786c6c6ed3c1553abe9579'
      '553e9393953c3a916ac56938'
      '53c3ac6ac5456c6a94513eac'
      '7856c55455795396e93ac785'
      '3c5551553952bc693aaa916d'
      '6d393a97e83aa956aaac6e95'
      '552ec6c13ec6ac57ac451569'
      '53a93d3aa915439169556954'
      '56aac16ac6c3baac54795695'
      '3ba83ab8393aaaab93ba93a9',
  ),
  MazeBoard(
    asset: 'assets/games/maze/maze_25.webp',
    size: 25,
    imageSize: 700,
    left: 104,
    right: 595,
    top: 107,
    bottom: 598,
    open:
      '2aaac2eec6aaaeac6eac46aec'
      '6aac3c1553a8696955693d451'
      '3c6d69693aaa9696953ac3d3c'
      '455156d6aaaac3c3c52c52b85'
      '39569153c6ac783c15693aac5'
      '6c556e9695693c69697eac455'
      '53d517c5693c693a94552bd3d'
      '3c13c55396c156aaeb93c6b85'
      '6d6c513aad3c556c56aad16a9'
      '515396c6c385555517c296968'
      '7a92e9393aa97953c13ac3c3c'
      '3aac3c686aaa943c56aad4569'
      '6ac5697c56aaad69552e9553c'
      '56d3945393c6855693c3c53c5'
      '553ac57aaa93a953aa943bc55'
      '55469556ac6aac546e87aa93d'
      '1553c393c552abd393a96ae85'
      '693ad6ac5556c456aaaa96d69'
      '7aac792d55395393ac6ac513c'
      '786d16c793ac3c6aa93c53e85'
      '569169516ac3ad52c6a93a969'
      '556a943a943ac13ad3ac6aa94'
      '53946d6ec7ac3eac56a93c6ed'
      '56c39395556943c153c6a9155'
      '393aaaa9393ab83ab83baaa91',
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
  MazeBoard(
    asset: 'assets/games/maze/maze_27.webp',
    size: 27,
    imageSize: 700,
    left: 104,
    right: 595,
    top: 107,
    bottom: 598,
    open:
      '2aac6aac686ac6c6aeac6eac2ac'
      '6e8396857c54393b852d13c3aad'
      '516ea969553d6ac6c3c3aa946c5'
      '5693ac56956938553a92ec6d539'
      '552ac3956d3aac552ec695553c4'
      '53aad2e9516e8553c553c39383d'
      '56ac3c383a93ab969556d6aaaa9'
      '556bc3c6ac6aaac5693953c6eac'
      '793c54394396ac557c2ab8513c5'
      '56853bc2fc2fc139556ac696a95'
      '53c3ac7a93c53ea8539693c3c29'
      '3c3ec516c453c56c3ac3e83c7ac'
      '43c553c553bc13d7ac543ac516d'
      '7a9178393ac3ac15453d6c55695'
      '3aac3aaeac3ac3c55569153952d'
      '6c696ac16bc45455553c6d6abc5'
      '5392fc3a96b957953b85553c695'
      '3aac156ac56e93a96aa953c5545'
      '6c45695455516aac3c6e9691555'
      '55555695393ab86d451543aa979'
      '539393ad6aec46d393c53ec6c3c'
      '7c6aaec556d39556aa97c5553a9'
      '1396ad155516a9156ac1553946c'
      '6ac5296915696aa93c3a956c795'
      '52bd6a96ad3c3ac6c3c46951569'
      '7ac152abc543c695569552ba93c'
      '383abaaa93b83ba9392bbaaaaa9',
  ),
  MazeBoard(
    asset: 'assets/games/maze/maze_28.webp',
    size: 28,
    imageSize: 700,
    left: 104,
    right: 595,
    top: 107,
    bottom: 598,
    open:
      '46aeaac6c2c6eeaaac6aaaac2aec'
      '55452c393c3d516ac53c6e83ac15'
      '5393c56ac3c53a9453a953aac3ad'
      '3aac57943a93aea956c692e83ac5'
      '46c553c3aec6c16c5513ac3aec39'
      '3953943c6939569397aac3ac17ac'
      '6abc6f853c6c552ea9683e83c529'
      '7c2953c3a95393c3ac7ac3e853ac'
      '53ac3c56ec56aa9469543c5696ad'
      '3c43c55551392ae93c3b8553c569'
      '43bc39393e86ea96a96c6d3c553c'
      '7e852aec43a93ac3c2d553c393c5'
      '53a96c53bc686c3a96939692ea95'
      '3ac69396855693aaad6ac3ac56a9'
      '6a93ac47a953ac6c695696c3952c'
      '3aac6953c696a95792d3c53e83ad'
      '6ac396d453ad6a916c5439456aa9'
      '3c7ae9393ac53c6a953d2ed53ac4'
      '693c56c6ac55453e8543a953aa95'
      '56c51555439393a9697aaa96aaad'
      '391569397eac6c6a943c6ac52c69'
      '6ac53c6c53c39396aba93c13c53c'
      '3c3b83955696aac52aeac3aeb96d'
      '696aec6915696c53ac7c3ac78695'
      '7a96913c69529556c51546916969'
      '3c43aac556bac3b913c53bc6943c'
      '43bac455556c56aae853c453c785'
      '3aaab93b93913ba83aba93ba93a9',
  ),
];
