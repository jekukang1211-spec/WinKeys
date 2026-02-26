const features = [
  {
    icon: "⚡",
    title: "Instant Mode Switch",
    desc: "Toggle between Windows and Mac mode with Ctrl+Alt+Shift+W/M. Works anywhere, anytime.",
  },
  {
    icon: "🖥️",
    title: "Terminal Safe",
    desc: "Automatically disables Ctrl remapping in 7 terminal apps. Ctrl+C stays SIGINT.",
  },
  {
    icon: "⌨️",
    title: "Customizable Shortcuts",
    desc: "Built-in shortcut editor to add or modify key mappings to fit your workflow.",
  },
  {
    icon: "🪶",
    title: "Lightweight",
    desc: "Runs as a menu bar app with minimal resource usage. No background daemons.",
  },
  {
    icon: "🌐",
    title: "Language Toggle Key",
    desc: "Configure any key (e.g. Right Alt) as a Korean/English language toggle.",
  },
  {
    icon: "🚀",
    title: "Launch at Login",
    desc: "One-click toggle to start WinKeys automatically when you log in to your Mac.",
  },
];

export default function Features() {
  return (
    <section id="features" className="py-20 px-4 bg-gray-50">
      <div className="max-w-5xl mx-auto">
        <h2 className="text-3xl font-bold text-center mb-4">Features</h2>
        <p className="text-center text-gray-500 mb-12 max-w-2xl mx-auto">
          Everything you need to feel at home on your Mac with Windows shortcuts.
        </p>
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((f) => (
            <div
              key={f.title}
              className="bg-white rounded-xl border border-gray-200 p-6 hover:shadow-md transition-shadow"
            >
              <div className="text-3xl mb-3">{f.icon}</div>
              <h3 className="font-semibold text-lg mb-2">{f.title}</h3>
              <p className="text-gray-600 text-sm leading-relaxed">{f.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
