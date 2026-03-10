import Foundation

@objc final class AutoCorrectItem: NSObject {
    @objc dynamic var replace: String
    @objc dynamic var with: String

    @objc override init() {
        self.replace = "replace"
        self.with = "with"
        super.init()
    }

    @objc init(replace: String, with: String) {
        self.replace = replace
        self.with = with
        super.init()
    }

    @objc func validateWith(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>,
                            error outError: NSErrorPointer) -> Bool {
        guard let value = ioValue.pointee as? String, !value.isEmpty else {
            if outError != nil {
                outError?.pointee = NSError(
                    domain: "iAvroErrorDomain",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey:
                        NSLocalizedString("Value of 'With' can't be empty",
                                          comment: "validation: Value of 'With' can't be empty")]
                )
            }
            return false
        }
        return true
    }
}
