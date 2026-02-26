"use client";

import { useState, useEffect, useCallback } from "react";

type Category = "Bug" | "Feature" | "App Request" | "Other";

interface FeedbackEntry {
  id: string;
  timestamp: string;
  name: string;
  category: string;
  appName?: string;
  shortcut?: string;
  message: string;
}

const categoryColors: Record<string, string> = {
  Bug: "bg-red-100 text-red-700",
  Feature: "bg-blue-100 text-blue-700",
  "App Request": "bg-purple-100 text-purple-700",
  Other: "bg-gray-100 text-gray-700",
};

function timeAgo(timestamp: string) {
  const diff = Date.now() - new Date(timestamp).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `${days}d ago`;
  return new Date(timestamp).toLocaleDateString();
}

export default function FeedbackForm() {
  const [entries, setEntries] = useState<FeedbackEntry[]>([]);
  const [name, setName] = useState("");
  const [category, setCategory] = useState<Category>("Bug");
  const [appName, setAppName] = useState("");
  const [shortcut, setShortcut] = useState("");
  const [message, setMessage] = useState("");
  const [status, setStatus] = useState<"idle" | "sending" | "error">("idle");

  const loadFeedback = useCallback(async () => {
    try {
      const res = await fetch("/api/feedback");
      if (res.ok) {
        const data = await res.json();
        setEntries(data);
      }
    } catch {
      // ignore
    }
  }, []);

  useEffect(() => {
    loadFeedback();
  }, [loadFeedback]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setStatus("sending");

    try {
      const res = await fetch("/api/feedback", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name,
          category,
          appName: appName || undefined,
          shortcut: shortcut || undefined,
          message,
        }),
      });

      if (res.ok) {
        const newEntry = await res.json();
        setEntries([newEntry, ...entries]);
        setName("");
        setAppName("");
        setShortcut("");
        setMessage("");
        setStatus("idle");
      } else {
        setStatus("error");
      }
    } catch {
      setStatus("error");
    }
  }

  const showAppField = category === "Bug" || category === "App Request";
  const showShortcutField = category === "Bug" || category === "Feature";

  return (
    <section id="feedback" className="py-20 px-4 bg-gray-50">
      <div className="max-w-2xl mx-auto">
        <h2 className="text-3xl font-bold text-center mb-4">Feedback Board</h2>
        <p className="text-center text-gray-500 mb-8">
          Report bugs, request features, or tell us which app to support next.
        </p>

        {/* Write form */}
        <form
          onSubmit={handleSubmit}
          className="bg-white rounded-xl border border-gray-200 p-5 mb-8"
        >
          {/* Row 1: Name + Category */}
          <div className="flex flex-col sm:flex-row items-start sm:items-center gap-3 mb-3">
            <input
              type="text"
              placeholder="Your name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
              className="w-full sm:w-auto sm:flex-1 px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#0078D4] focus:border-transparent"
            />
            <div className="flex gap-1 flex-wrap">
              {(["Bug", "Feature", "App Request", "Other"] as Category[]).map((cat) => (
                <button
                  key={cat}
                  type="button"
                  onClick={() => setCategory(cat)}
                  className={`px-3 py-2 rounded-lg text-xs font-medium transition-colors ${
                    category === cat
                      ? "bg-[#0078D4] text-white"
                      : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                  }`}
                >
                  {cat}
                </button>
              ))}
            </div>
          </div>

          {/* Row 2: App name + Shortcut (conditional) */}
          {(showAppField || showShortcutField) && (
            <div className="flex gap-3 mb-3">
              {showAppField && (
                <input
                  type="text"
                  placeholder="App name (e.g. Chrome, VS Code, Notion)"
                  value={appName}
                  onChange={(e) => setAppName(e.target.value)}
                  className="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#0078D4] focus:border-transparent"
                />
              )}
              {showShortcutField && (
                <input
                  type="text"
                  placeholder="Shortcut (e.g. Ctrl+C, Alt+Tab)"
                  value={shortcut}
                  onChange={(e) => setShortcut(e.target.value)}
                  className="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#0078D4] focus:border-transparent"
                />
              )}
            </div>
          )}

          {/* Row 3: Message */}
          <textarea
            placeholder={
              category === "Bug"
                ? "What happened? What did you expect?"
                : category === "App Request"
                  ? "Which app do you want WinKeys to support? What shortcuts are missing?"
                  : category === "Feature"
                    ? "Describe the feature you'd like..."
                    : "Write your feedback..."
            }
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            required
            rows={3}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#0078D4] focus:border-transparent resize-none mb-3"
          />

          {status === "error" && (
            <p className="text-red-600 text-sm mb-2">Failed to post. Please try again.</p>
          )}
          <div className="flex justify-end">
            <button
              type="submit"
              disabled={status === "sending"}
              className="bg-[#0078D4] text-white font-semibold px-6 py-2 rounded-lg text-sm hover:bg-[#005A9E] transition-colors disabled:opacity-60"
            >
              {status === "sending" ? "Posting..." : "Post"}
            </button>
          </div>
        </form>

        {/* Feedback list */}
        {entries.length === 0 ? (
          <p className="text-center text-gray-400 text-sm py-8">
            No feedback yet. Be the first to post!
          </p>
        ) : (
          <div className="space-y-3">
            {entries.map((entry) => (
              <div
                key={entry.id}
                className="bg-white rounded-xl border border-gray-200 p-5"
              >
                <div className="flex items-center gap-2 mb-2 flex-wrap">
                  <div className="w-7 h-7 rounded-full bg-[#0078D4] text-white flex items-center justify-center text-xs font-bold flex-shrink-0">
                    {entry.name.charAt(0).toUpperCase()}
                  </div>
                  <span className="font-medium text-sm">{entry.name}</span>
                  <span
                    className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                      categoryColors[entry.category] || categoryColors.Other
                    }`}
                  >
                    {entry.category}
                  </span>
                  {entry.appName && (
                    <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
                      {entry.appName}
                    </span>
                  )}
                  {entry.shortcut && (
                    <kbd className="px-1.5 py-0.5 bg-gray-100 border border-gray-300 border-b-2 rounded text-xs font-mono">
                      {entry.shortcut}
                    </kbd>
                  )}
                  <span className="text-xs text-gray-400 ml-auto">
                    {timeAgo(entry.timestamp)}
                  </span>
                </div>
                <p className="text-sm text-gray-700 leading-relaxed whitespace-pre-wrap">
                  {entry.message}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>
    </section>
  );
}
