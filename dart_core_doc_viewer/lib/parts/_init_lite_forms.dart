part of '../main.dart';

void _initLiteForms(
  BuildContext context,
) {
  const cornerRadius = kBorderRadius;
  const defaultBorder = OutlineInputBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(
        cornerRadius,
      ),
      topRight: Radius.circular(
        cornerRadius,
      ),
      bottomRight: Radius.circular(
        cornerRadius,
      ),
      bottomLeft: Radius.circular(
        cornerRadius,
      ),
    ),
  );

  const borderWidth = 2.0;
  initializeLiteForms(
    /// optional configuration which will be used as default
    config: LiteFormsConfiguration(
      defaultDateFormat: 'dd MMM, yyyy',
      defaultTimeFormat: 'HH:mm',
      dropSelectorSettings: const DropSelectorSettings(
        sheetPadding: EdgeInsets.all(kPadding),
        dropSelectorActionType: null,
        dropSelectorType: null,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      useAutogeneratedHints: true,
      allowUnfocusOnTapOutside: true,
      defaultTextEntryModalRouteSettings: TextEntryModalRouteSettings(
        backgroundOpacity: .95,
      ),
      lightTheme: LiteFormsTheme(
        defaultTextStyle: CustomTextTheme.of(context).defaultStyle,
        filePickerDecoration: const BoxDecoration(
          color: Color.fromARGB(255, 239, 239, 239),
          borderRadius: BorderRadius.all(
            Radius.circular(
              cornerRadius,
            ),
          ),
        ),
        inputDecoration: InputDecoration(
          filled: true,
          contentPadding: const EdgeInsets.only(
            left: kPadding,
            right: kPadding,
            top: 8.0,
            bottom: 8.0,
          ),
          errorStyle: TextStyle(
            fontSize: 16.0,
            color: CustomColorTheme.of(context).negativeColor,
          ),
          fillColor: const Color.fromARGB(255, 239, 239, 239),
          border: defaultBorder,
          enabledBorder: defaultBorder.copyWith(
            borderSide: const BorderSide(
              width: borderWidth,
              color: Colors.transparent,
            ),
          ),
          focusedBorder: defaultBorder.copyWith(
            borderSide: BorderSide(
              width: borderWidth,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
      darkTheme: LiteFormsTheme(
        defaultTextStyle: CustomTextTheme.of(context).defaultStyle,
        filePickerDecoration: const BoxDecoration(
          color: Color.fromARGB(255, 57, 57, 57),
          borderRadius: BorderRadius.all(
            Radius.circular(
              cornerRadius,
            ),
          ),
        ),
        inputDecoration: InputDecoration(
          filled: true,
          fillColor: const Color.fromARGB(255, 57, 57, 57),
          contentPadding: const EdgeInsets.only(
            left: kPadding,
            right: kPadding,
            top: 8.0,
            bottom: 8.0,
          ),
          errorStyle: TextStyle(
            fontSize: 16.0,
            color: CustomColorTheme.of(context).negativeColor,
          ),
          border: defaultBorder,
          enabledBorder: defaultBorder.copyWith(
            borderSide: const BorderSide(
              width: borderWidth,
              color: Colors.transparent,
            ),
          ),
          focusedBorder: defaultBorder.copyWith(
            borderSide: BorderSide(
              width: borderWidth,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    ),
  );
}
