export default function Hero() {
  return (
    <section className="bg-gradient-to-br from-[#0078D4] to-[#005A9E] text-white text-center py-20 px-4">
      <h1 className="text-4xl md:text-5xl font-bold tracking-tight mb-4">
        WinKeys <span className="font-light opacity-70">for Mac</span>
      </h1>
      <p className="text-lg md:text-xl opacity-90 max-w-xl mx-auto mb-8">
        Use your familiar Windows keyboard shortcuts on Mac.
        <br className="hidden sm:block" />
        Lightweight. No Karabiner needed.
      </p>

      <div className="flex flex-wrap gap-3 justify-center mb-8">
        {["macOS 13+", "Lightweight", "No Karabiner", "16 Languages"].map((badge) => (
          <span
            key={badge}
            className="px-4 py-1.5 text-sm rounded-full border border-white/30 bg-white/15"
          >
            {badge}
          </span>
        ))}
      </div>

      <a
        href="#download"
        className="inline-block bg-white text-[#0078D4] font-semibold px-8 py-3 rounded-lg hover:bg-gray-100 transition-colors"
      >
        Download Free Beta
      </a>
    </section>
  );
}
