/// A named simulated device width for the Storybook stage.
class DevicePreset {
  const DevicePreset(this.name, this.width);
  final String name;
  final double width;

  static const iphoneSE = DevicePreset('iPhone SE', 375.0);
  static const iphone16 = DevicePreset('iPhone 16', 393.0);
  static const proMax = DevicePreset('iPhone Pro Max', 430.0);
  static const ipad = DevicePreset('iPad', 820.0);
  static const desktop = DevicePreset('Desktop', 1200.0);

  static const List<DevicePreset> defaults = [
    iphoneSE,
    iphone16,
    proMax,
    ipad,
    desktop,
  ];
}
