# Media Manager App

Ứng dụng iOS để quản lý và tổ chức tập tin đa phương tiện (hình ảnh và video) với giao diện menu bên và các tính năng mạnh mẽ.

## Tính năng chính

- 📱 Giao diện trực quan với menu bên có thể mở rộng/thu gọn
- 🖼️ Quản lý hình ảnh và video từ thư viện ảnh
- 📂 Phân loại và tổ chức tập tin theo danh mục
- 🔄 Tự động tạo thumbnail cho ảnh và video
- 💾 Lưu trữ và quản lý dữ liệu hiệu quả với Core Data
- 📊 Bộ nhớ đệm thông minh để tối ưu hiệu suất

## Kiến trúc

### View Controllers

#### ContainerViewController
- Controller chính quản lý layout tổng thể của ứng dụng
- Xử lý menu bên và điều hướng giữa các màn hình
- Hỗ trợ các thao tác vuốt để mở/đóng menu
- Tự động điều chỉnh layout khi xoay màn hình

#### HomeViewController
- Hiển thị danh sách các danh mục phương tiện
- Quản lý trạng thái tải và hiển thị dữ liệu
- Xử lý quyền truy cập thư viện ảnh
- Cung cấp khả năng làm mới dữ liệu

#### ListViewController
- Hiển thị chi tiết các mục trong danh mục
- Hỗ trợ chế độ chọn nhiều và xóa mục
- Tích hợp với trình chiếu phương tiện
- Tự động cập nhật khi có thay đổi dữ liệu

#### SideMenuController
- Quản lý giao diện menu bên
- Xử lý điều hướng và tương tác người dùng
- Tích hợp với ContainerViewController

#### MediaPresentationController
- Trình bày phương tiện dưới dạng modal
- Tự động điều chỉnh layout khi xoay màn hình
- Hỗ trợ overlay tùy chỉnh

### Quản lý dữ liệu

#### DataManager
- Quản lý thao tác CRUD với Core Data
- Xử lý bộ nhớ đệm cho ảnh
- Tối ưu hóa lưu trữ với thumbnail
- Hỗ trợ lưu hàng loạt tập tin

#### CoreDataManager
- Singleton quản lý Core Data stack
- Cung cấp context cho các thao tác dữ liệu
- Đảm bảo tính nhất quán của dữ liệu

## Yêu cầu

- iOS 15.0+
- Xcode 13.0+
- Swift 5.0+

## Cài đặt

1. Clone repository
2. Mở file `.xcodeproj` bằng Xcode
3. Build và chạy ứng dụng

## Sử dụng

### Khởi động
```swift
// Trong SceneDelegate
func scene(_ scene: UIScene, willConnectTo session: UISceneSession...) {
    guard let windowScene = scene as? UIWindowScene else { return }
    window = UIWindow(windowScene: windowScene)
    window?.rootViewController = ContainerViewController()
    window?.makeKeyAndVisible()
}
```

### Quản lý dữ liệu
```swift
// Khởi tạo DataManager
let dataManager = DataManager(context: CoreDataManager.shared.context, mediaType: "image")

// Lấy dữ liệu
dataManager.fetchData { result in
    switch result {
    case .success(let items):
        // Xử lý dữ liệu
    case .failure(let error):
        // Xử lý lỗi
    }
}
```

## Kiến trúc dữ liệu

### Core Data Entity: AppMedia
- `id`: String (identifier)
- `mediaType`: String (image/video)
- `name`: String
- `data`: Binary Data (thumbnail)
- `createdAt`: Date
- `updatedAt`: Date
- `duration`: Double

## Xử lý bộ nhớ

- Tự động xóa bộ nhớ đệm khi nhận cảnh báo bộ nhớ thấp
- Giới hạn kích thước bộ nhớ đệm (100 ảnh hoặc 50MB)
- Tối ưu hóa kích thước thumbnail

## Góp ý và báo lỗi

Nếu bạn phát hiện lỗi hoặc có góp ý để cải thiện ứng dụng, vui lòng tạo issue trong repository.

## Giấy phép

[MIT License](LICENSE)
