import Foundation

enum Constants {
    static let accessKey: String = "PuXt-cezInaTLVFiweA2HarCQrVIC-9pdeFTlvYWABs"
    static let secretKey: String = "zvRwy4XdxaDpi5n7FvQ2z2ktxILX2YqHSdcVDQAO4Y0"
    static let redirectURI: String = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope: String = "public+read_user+write_likes"
    static let defaultBaseURLString: String = "https://api.unsplash.com"
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
}

struct AuthConfiguration {
    let accessKey: String
    let secretKey: String
    let redirectURI: String
    let accessScope: String
    let defaultBaseURLString: String
    let authURLString: String

    static var standard: AuthConfiguration {
        return AuthConfiguration(
            accessKey: Constants.accessKey,
            secretKey: Constants.secretKey,
            redirectURI: Constants.redirectURI,
            accessScope: Constants.accessScope,
            defaultBaseURLString: Constants.defaultBaseURLString,
            authURLString: Constants.unsplashAuthorizeURLString
        )
    }
}
