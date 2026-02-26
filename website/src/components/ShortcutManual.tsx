"use client";

import { useState } from "react";
import {
  allShortcutGroups,
  modeShortcuts,
  type ShortcutGroup,
} from "@/lib/shortcuts";
import { TERMINAL_APPS } from "@/lib/constants";

function ShortcutTable({ group }: { group: ShortcutGroup }) {
  return (
    <div className="mb-10">
      <h3 className="text-xl font-semibold mb-1">{group.title}</h3>
      <p className="text-gray-500 text-sm mb-4">{group.description}</p>
      <div className="overflow-x-auto rounded-xl border border-gray-200">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-[#0078D4] text-white">
              <th className="text-left px-4 py-3 font-semibold">Windows</th>
              <th className="text-left px-4 py-3 font-semibold">Mac</th>
              <th className="text-left px-4 py-3 font-semibold">Function</th>
            </tr>
          </thead>
          <tbody className="bg-white">
            {group.shortcuts.map((s, i) => (
              <tr key={i} className="border-t border-gray-100 hover:bg-blue-50/50">
                <td className="px-4 py-2.5">
                  <Kbd text={s.windows} />
                </td>
                <td className="px-4 py-2.5">
                  <Kbd text={s.mac} />
                </td>
                <td className="px-4 py-2.5 text-gray-600">{s.fn}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function Kbd({ text }: { text: string }) {
  if (text === "—") return <span className="text-gray-400">—</span>;
  return (
    <span className="font-mono text-xs">
      {text.split(/(\s*[+/]\s*)/).map((part, i) => {
        const trimmed = part.trim();
        if (trimmed === "+" || trimmed === "/") {
          return (
            <span key={i} className="mx-0.5 text-gray-400">
              {trimmed}
            </span>
          );
        }
        if (!trimmed) return null;
        return (
          <kbd
            key={i}
            className="inline-block px-1.5 py-0.5 bg-gray-100 border border-gray-300 border-b-2 rounded text-xs"
          >
            {trimmed}
          </kbd>
        );
      })}
    </span>
  );
}

const tabs = ["Global", "General Apps", "Finder", "Terminal", "Mode Toggle"];

export default function ShortcutManual() {
  const [active, setActive] = useState(0);

  return (
    <section id="shortcuts" className="py-20 px-4">
      <div className="max-w-5xl mx-auto">
        <h2 className="text-3xl font-bold text-center mb-4">Shortcut Manual</h2>
        <p className="text-center text-gray-500 mb-8 max-w-2xl mx-auto">
          Complete reference of Windows-to-Mac shortcut mappings, organized by scope.
        </p>

        {/* Tabs */}
        <div className="flex flex-wrap gap-2 justify-center mb-8">
          {tabs.map((tab, i) => (
            <button
              key={tab}
              onClick={() => setActive(i)}
              className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
                active === i
                  ? "bg-[#0078D4] text-white"
                  : "bg-gray-100 text-gray-600 hover:bg-gray-200"
              }`}
            >
              {tab}
            </button>
          ))}
        </div>

        {/* Tab content */}
        {active < 3 && <ShortcutTable group={allShortcutGroups[active]} />}

        {active === 3 && (
          <div className="mb-10">
            <h3 className="text-xl font-semibold mb-1">Terminal Apps (Auto-excluded)</h3>
            <p className="text-gray-500 text-sm mb-4">
              Ctrl key remapping is automatically disabled in terminal apps to preserve
              native behavior (Ctrl+C = SIGINT, Ctrl+Z = suspend, etc.).
            </p>
            <div className="bg-white rounded-xl border border-gray-200 p-6">
              <p className="font-medium mb-3">Excluded terminal apps:</p>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                {TERMINAL_APPS.map((app) => (
                  <div
                    key={app}
                    className="flex items-center gap-2 text-sm text-gray-700"
                  >
                    <span className="w-2 h-2 rounded-full bg-[#0078D4]" />
                    {app}
                  </div>
                ))}
              </div>
              <div className="mt-4 p-3 bg-blue-50 rounded-lg text-sm text-blue-800">
                System shortcuts (Alt+Tab, Win+D, etc.) and navigation keys (Home/End)
                still work in terminal apps.
              </div>
            </div>
          </div>
        )}

        {active === 4 && (
          <div className="mb-10">
            <h3 className="text-xl font-semibold mb-1">Mode Toggle</h3>
            <p className="text-gray-500 text-sm mb-4">
              These shortcuts always work regardless of the current mode.
            </p>
            <div className="overflow-x-auto rounded-xl border border-gray-200">
              <table className="w-full text-sm">
                <thead>
                  <tr className="bg-[#0078D4] text-white">
                    <th className="text-left px-4 py-3 font-semibold">Shortcut</th>
                    <th className="text-left px-4 py-3 font-semibold">Action</th>
                  </tr>
                </thead>
                <tbody className="bg-white">
                  {modeShortcuts.map((s, i) => (
                    <tr key={i} className="border-t border-gray-100 hover:bg-blue-50/50">
                      <td className="px-4 py-2.5">
                        <Kbd text={s.shortcut} />
                      </td>
                      <td className="px-4 py-2.5 text-gray-600">{s.action}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <p className="mt-4 text-sm text-gray-500">
              You can also toggle modes via the menu bar icon (W/M).
            </p>
          </div>
        )}
      </div>
    </section>
  );
}
