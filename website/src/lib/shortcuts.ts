export interface Shortcut {
  windows: string;
  mac: string;
  fn: string;
}

export interface ShortcutGroup {
  title: string;
  description: string;
  shortcuts: Shortcut[];
}

export const globalShortcuts: ShortcutGroup = {
  title: "Global Shortcuts",
  description: "Work in all apps, including terminals.",
  shortcuts: [
    { windows: "Alt+Tab", mac: "Cmd+Tab", fn: "Switch apps" },
    { windows: "Alt+F4", mac: "Cmd+Q", fn: "Quit app" },
    { windows: "Ctrl+Shift+Esc", mac: "Cmd+Option+Esc", fn: "Force quit" },
    { windows: "Win+D", mac: "F11", fn: "Show desktop" },
    { windows: "Win+E", mac: "—", fn: "Open Finder" },
    { windows: "Win+L", mac: "Ctrl+Cmd+Q", fn: "Lock screen" },
    { windows: "Win+R", mac: "Cmd+Space", fn: "Spotlight" },
    { windows: "PrintScreen", mac: "Cmd+Shift+3", fn: "Full screenshot" },
    { windows: "Alt+PrintScreen", mac: "Cmd+Shift+4+Space", fn: "Window capture" },
    { windows: "Shift+PrintScreen", mac: "Cmd+Shift+5", fn: "Screenshot tool" },
    { windows: "Win+Shift+S", mac: "Cmd+Shift+4", fn: "Area selection" },
  ],
};

export const generalShortcuts: ShortcutGroup = {
  title: "General Apps",
  description: "Work in all apps except terminals (browsers, editors, office, etc.).",
  shortcuts: [
    { windows: "Ctrl+C / V / X", mac: "Cmd+C / V / X", fn: "Copy / Paste / Cut" },
    { windows: "Ctrl+Z", mac: "Cmd+Z", fn: "Undo" },
    { windows: "Ctrl+Y", mac: "Cmd+Shift+Z", fn: "Redo" },
    { windows: "Ctrl+A", mac: "Cmd+A", fn: "Select all" },
    { windows: "Ctrl+S", mac: "Cmd+S", fn: "Save" },
    { windows: "Ctrl+F", mac: "Cmd+F", fn: "Find" },
    { windows: "Ctrl+N", mac: "Cmd+N", fn: "New" },
    { windows: "Ctrl+O", mac: "Cmd+O", fn: "Open" },
    { windows: "Ctrl+P", mac: "Cmd+P", fn: "Print" },
    { windows: "Ctrl+T", mac: "Cmd+T", fn: "New tab" },
    { windows: "Ctrl+W", mac: "Cmd+W", fn: "Close tab" },
    { windows: "Ctrl+Shift+T", mac: "Cmd+Shift+T", fn: "Restore tab" },
    { windows: "Ctrl+R / F5", mac: "Cmd+R", fn: "Refresh" },
    { windows: "Ctrl+L", mac: "Cmd+L", fn: "Address bar" },
    { windows: "Ctrl+B / I / U", mac: "Cmd+B / I / U", fn: "Bold / Italic / Underline" },
    { windows: "Home / End", mac: "Cmd+\u2190 / \u2192", fn: "Line start / end" },
    { windows: "Ctrl+Home / End", mac: "Cmd+\u2191 / \u2193", fn: "Document start / end" },
    { windows: "Ctrl+\u2190 / \u2192", mac: "Option+\u2190 / \u2192", fn: "Word jump" },
    { windows: "Ctrl+Backspace", mac: "Option+Backspace", fn: "Delete word" },
    { windows: "+ Shift variants", mac: "+ Shift variants", fn: "Selection variants" },
  ],
};

export const finderShortcuts: ShortcutGroup = {
  title: "Finder Only",
  description: "These shortcuts work exclusively in Finder.",
  shortcuts: [
    { windows: "F2", mac: "Enter", fn: "Rename" },
    { windows: "Enter", mac: "Cmd+O", fn: "Open" },
    { windows: "Delete", mac: "Cmd+Backspace", fn: "Move to Trash" },
    { windows: "Backspace", mac: "Cmd+\u2191", fn: "Parent folder" },
    { windows: "Alt+Enter", mac: "Cmd+I", fn: "File info" },
  ],
};

export const modeShortcuts = [
  { shortcut: "Ctrl+Alt+Shift+W", action: "Switch to Windows mode" },
  { shortcut: "Ctrl+Alt+Shift+M", action: "Switch to Mac mode" },
];

export const allShortcutGroups = [globalShortcuts, generalShortcuts, finderShortcuts];
