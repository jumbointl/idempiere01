// `PrinterSetupScreen` (and the helper `LocatorTemplateSheet` + the
// `OpenMoPrinterEditor` / `OpenLocatorSentenceEditor` callback typedefs)
// now lives in `monalisapy_features`. Re-exported so the app's own
// subclasses (m_in_out_print_screen, movement_print_screen,
// locator_print_screen) keep extending it without changing imports.
export 'package:monalisapy_features/printer/screens/printer_setup_screen.dart'
    show
        PrinterSetupScreen,
        PrinterSetupScreenState,
        LocatorTemplateSheet,
        OpenMoPrinterEditor,
        OpenLocatorSentenceEditor;
