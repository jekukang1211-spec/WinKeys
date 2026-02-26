"use client";

import { useState } from "react";

const faqs = [
  {
    q: "Shortcuts aren\u2019t working at all",
    a: "Go to System Settings > Privacy & Security > Accessibility. Remove WinKeys (\u2212 button), then re-add it (+ button) and enable the toggle. Restart the app after granting permission.",
  },
  {
    q: "Ctrl+C doesn\u2019t work in terminal",
    a: "This is by design. WinKeys automatically disables Ctrl remapping in terminal apps (Terminal, iTerm2, Ghostty, Kitty, Alacritty, Hyper, Warp) so that Ctrl+C sends SIGINT as expected.",
  },
  {
    q: "Shortcuts don\u2019t work in a specific app",
    a: "Some apps may intercept keyboard events before WinKeys can process them. Check if the app is in Windows mode (W icon in menu bar). If the issue persists, please report it via the feedback form.",
  },
  {
    q: "Language toggle key isn\u2019t working",
    a: "Click the W icon in the menu bar > Language Toggle Key Settings. Press the key you want to use (e.g. Right Alt). The setting persists across restarts.",
  },
  {
    q: "How do I start WinKeys at login?",
    a: "Click the W icon in the menu bar and enable \"Launch at Login\". WinKeys will start automatically next time you log in.",
  },
  {
    q: "How do I uninstall WinKeys?",
    a: "Quit WinKeys from the menu bar, then drag WinKeys.app from /Applications to the Trash. Optionally, remove it from Accessibility permissions in System Settings.",
  },
  {
    q: "How is this different from Karabiner-Elements?",
    a: "WinKeys is purpose-built for Windows-to-Mac shortcut mapping. It\u2019s lightweight, requires no complex configuration, and works out of the box. Karabiner is a general-purpose remapper with much broader scope but more complexity.",
  },
  {
    q: "Is the Accessibility permission safe?",
    a: "Yes. The Accessibility permission allows WinKeys to read and transform keyboard events. WinKeys does not log keystrokes or send any data externally. All processing happens locally on your Mac.",
  },
];

export default function FAQ() {
  const [openIdx, setOpenIdx] = useState<number | null>(null);

  return (
    <section id="faq" className="py-20 px-4">
      <div className="max-w-3xl mx-auto">
        <h2 className="text-3xl font-bold text-center mb-4">FAQ</h2>
        <p className="text-center text-gray-500 mb-8">
          Common questions and troubleshooting tips.
        </p>
        <div className="space-y-3">
          {faqs.map((faq, i) => (
            <div
              key={i}
              className="bg-white rounded-xl border border-gray-200 overflow-hidden"
            >
              <button
                className="w-full flex items-center justify-between px-5 py-4 text-left font-medium hover:bg-gray-50 transition-colors"
                onClick={() => setOpenIdx(openIdx === i ? null : i)}
              >
                <span>{faq.q}</span>
                <svg
                  className={`w-5 h-5 text-[#0078D4] flex-shrink-0 transition-transform ${
                    openIdx === i ? "rotate-45" : ""
                  }`}
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 4v16m8-8H4"
                  />
                </svg>
              </button>
              {openIdx === i && (
                <div className="px-5 pb-4 text-gray-600 text-sm leading-relaxed">
                  {faq.a}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
