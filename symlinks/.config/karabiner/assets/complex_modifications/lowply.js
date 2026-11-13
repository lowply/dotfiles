function main() {
  return {
    description: "@lowply's keymaps",
    manipulators: [
      controlArrow("h", "left_arrow"),
      controlArrow("j", "down_arrow"),
      controlArrow("k", "up_arrow"),
      controlArrow("l", "right_arrow"),
    ].map(function (manipulator) {
      manipulator.type = "basic";
      manipulator.conditions = [
        {
          type: "device_if",
          // Matches either the Apple Internal Keyboard or HHKB Studio.
          identifiers: [
            { is_built_in_keyboard: true },
            { vendor_id: 1278, product_id: 22, is_keyboard: true },
          ],
        },
      ];
      return manipulator;
    }),
  };
}

function controlArrow(key, arrow) {
  return {
    from: {
      key_code: key,
      modifiers: {
        mandatory: ["left_control"],
        optional: ["any"],
      },
    },
    to: [{ key_code: arrow }],
  };
}

main();
