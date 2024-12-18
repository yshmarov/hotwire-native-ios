public enum Navigation {
    public enum Context: String {
        case `default`
        case modal
    }

    public enum Presentation: String {
        case `default`
        case pop
        case replace
        case refresh
        case clearAll = "clear_all"
        case replaceRoot = "replace_root"
        case none
    }

    public enum ModalStyle: String {
        case medium
        case large
        case full
        case pageSheet = "page_sheet"
        case formSheet = "form_sheet"
    }
}
