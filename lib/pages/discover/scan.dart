import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/toast.dart';

// 扫一扫
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with SingleTickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController();
  late AnimationController _animationController;

  // 使用响应式尺寸变量
  late double scanAreaSize;
  late double screenWidth;
  late double screenHeight;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _checkPermission();
  }

  // 检查权限
  Future<void> _checkPermission() async {
    // 查看相机权限状态
    final status = await Permission.camera.request();
    // 如果是已拒绝
    if (status.isDenied) {
      ToastUtils.showGlobalToast(msg: '您已拒绝授予相机权限');
      Navigator.pop(context);
      return;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在依赖变化时更新响应式尺寸
    _updateResponsiveDimensions();
  }

  // 更新响应式尺寸
  void _updateResponsiveDimensions() {
    screenWidth = MediaQuery.sizeOf(context).width;
    screenHeight = MediaQuery.sizeOf(context).height;
    // 扫描区域设为屏幕宽度的70%，最大不超过400，最小不小于200
    scanAreaSize = (screenWidth * 0.7).clamp(200.w, 400.w);
  }

  @override
  void dispose() {
    cameraController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 确保尺寸是最新的
    _updateResponsiveDimensions();

    // 计算响应式尺寸
    final topBottomMargin = (screenHeight - scanAreaSize) / 2;
    final leftRightMargin = (screenWidth - scanAreaSize) / 2;

    return Scaffold(
      body: Stack(
        children: [
          // 全屏摄像头预览
          Positioned.fill(
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String code = barcodes.first.rawValue ?? '';
                  if (code.isNotEmpty) {
                    // 处理扫描到的二维码
                    _onQRCodeScanned(code);
                  }
                }
              },
            ),
          ),

          // 顶部半透明遮罩
          _buildOverlaySection(height: topBottomMargin, top: 0),

          // 底部半透明遮罩
          _buildOverlaySection(height: topBottomMargin, bottom: 0),

          // 扫描窗口边框
          Center(
            child: Container(
              width: scanAreaSize,
              height: scanAreaSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.w),
              ),
            ),
          ),

          // 扫描窗口四个角
          _buildCorner(
            top: topBottomMargin - 2.w,
            left: leftRightMargin - 2.w,
            isTopLeft: true,
          ),
          _buildCorner(
            top: topBottomMargin - 2.w,
            right: leftRightMargin - 2.w,
            isTopRight: true,
          ),
          _buildCorner(
            bottom: topBottomMargin - 2.w,
            left: leftRightMargin - 2.w,
            isBottomLeft: true,
          ),
          _buildCorner(
            bottom: topBottomMargin - 2.w,
            right: leftRightMargin - 2.w,
            isBottomRight: true,
          ),

          // 扫描波纹效果
          _buildScanLine(scanAreaSize),

          // 提示文字
          Positioned(
            top: topBottomMargin + scanAreaSize + 20.h,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  '将二维码放入框内，即可自动扫描',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // 顶部操作栏
          Positioned(
            top: MediaQuery.paddingOf(context).top,
            left: 0,
            right: 0,
            child: Row(
              children: [
                SizedBox(width: 8.w),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 24.w,
                  ),
                  iconSize: 24.w,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '扫一扫',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _toggleFlash,
                  icon: ValueListenableBuilder(
                    valueListenable: cameraController,
                    builder: (context, state, child) {
                      return Icon(
                        state.torchState == TorchState.on
                            ? Icons.flash_on
                            : Icons.flash_off,
                        color: Colors.white,
                        size: 24.w,
                      );
                    },
                  ),
                  iconSize: 24.w,
                ),
                SizedBox(width: 8.w),
              ],
            ),
          ),

          // 底部操作栏
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 20.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.photo_library,
                  text: '相册',
                  onTap: _pickImageFromGallery,
                ),
                _buildActionButton(
                  icon: Icons.qr_code,
                  text: '我的二维码',
                  onTap: _showMyQRCode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建半透明遮罩区域
  Widget _buildOverlaySection({
    double? width,
    double? height,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: width,
        height: height,
        color: Color.fromRGBO(0, 0, 0, 0.6),
      ),
    );
  }

  // 构建扫描窗口四个角
  Widget _buildCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: SizedBox(
        width: 20.w,
        height: 20.w,
        child: CustomPaint(
          painter: _CornerPainter(
            isTopLeft: isTopLeft,
            isTopRight: isTopRight,
            isBottomLeft: isBottomLeft,
            isBottomRight: isBottomRight,
          ),
        ),
      ),
    );
  }

  // 自定义扫描线
  Widget _buildScanLine(double scanAreaSize) {
    return Center(
      child: SizedBox(
        width: scanAreaSize - 20.w,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                0,
                (scanAreaSize - 40.w) * _animationController.value -
                    (scanAreaSize - 40.w) / 2,
              ),
              child: Container(
                height: 2.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color.fromRGBO(20, 134, 237, 0.8), // 微信绿色
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(20, 134, 237, 0.5),
                      blurRadius: 4.w,
                      spreadRadius: 2.w,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            color: Color.fromRGBO(0, 0, 0, 0.4),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: Colors.white, size: 28.w),
            iconSize: 28.w,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // 处理扫描到的二维码
  void _onQRCodeScanned(String code) {
    // 停止扫描避免重复
    cameraController.stop();

    // 振动反馈
    HapticFeedback.mediumImpact();

    // TODO 处理二维码
    print('处理二维码: $code');

    // TODO 如果解析二维码失败，提示用户并继续扫描
  }

  // 切换闪光灯
  void _toggleFlash() {
    cameraController.toggleTorch();
  }

  // 从相册选择图片
  Future<void> _pickImageFromGallery() async {
    // 图片选择器
    final picker = ImagePicker();
    // 等待用户从相册中选择图片
    final image = await picker.pickImage(source: ImageSource.gallery);
    // 用户没有选择图片
    if (image != null) {
      // 解析图片
      final capture = await cameraController.analyzeImage(image.path);
      if (capture != null && capture.barcodes.isNotEmpty) {
        final String? code = capture.barcodes.first.rawValue;
        print('从相册选择图片 扫描结果: $code');
      } else {
        ToastUtils.showGlobalToast(msg: '没有解析出二维码');
      }
    }
  }

  // 显示我的二维码
  void _showMyQRCode() {
    // 跳转到我的二维码页面
    Navigator.pushNamed(context, RoutePath.myQRCode);
  }
}

// 自定义四个角的绘制
class _CornerPainter extends CustomPainter {
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  _CornerPainter({
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制扫描框角落
    final paint = Paint()
      ..color = Color.fromRGBO(20, 134, 237, 1)
      ..strokeWidth = 4.w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 扫描框各个角的长度，响应式
    final cornerLength = 15.w;

    if (isTopLeft) {
      // 左上角
      canvas.drawLine(Offset(0, cornerLength), Offset(0, 0), paint);
      canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);
    } else if (isTopRight) {
      // 右上角
      canvas.drawLine(
        Offset(size.width - cornerLength, 0),
        Offset(size.width, 0),
        paint,
      );
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, cornerLength),
        paint,
      );
    } else if (isBottomLeft) {
      // 左下角
      canvas.drawLine(
        Offset(0, size.height - cornerLength),
        Offset(0, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, size.height),
        Offset(cornerLength, size.height),
        paint,
      );
    } else if (isBottomRight) {
      // 右下角
      canvas.drawLine(
        Offset(size.width - cornerLength, size.height),
        Offset(size.width, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(size.width, size.height - cornerLength),
        Offset(size.width, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
