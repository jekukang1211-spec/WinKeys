import { APP_VERSION, MIN_MACOS, DOWNLOAD_URL } from "@/lib/constants";

export default function Download() {
  return (
    <section id="download" className="py-20 px-4 bg-gray-50">
      <div className="max-w-3xl mx-auto">
        <h2 className="text-3xl font-bold text-center mb-4">Download</h2>
        <p className="text-center text-gray-500 mb-8">
          Free beta — try WinKeys and share your feedback.
        </p>

        {/* Download card */}
        <div className="bg-white rounded-xl border border-gray-200 p-8 text-center mb-10">
          <div className="inline-flex items-center gap-2 mb-4">
            <span className="text-xs font-mono bg-gray-100 px-2 py-1 rounded">
              v{APP_VERSION}
            </span>
            <span className="text-xs text-gray-500">{MIN_MACOS} or later</span>
          </div>
          <div>
            <a
              href={DOWNLOAD_URL}
              className="inline-block bg-[#0078D4] text-white font-semibold px-8 py-3 rounded-lg hover:bg-[#005A9E] transition-colors"
            >
              Download WinKeys_{APP_VERSION}.zip
            </a>
          </div>
        </div>

        {/* Installation steps */}
        <h3 className="text-xl font-semibold mb-6">Installation Guide</h3>
        <ol className="space-y-4">
          {[
            {
              title: "Download & Extract",
              desc: "Download the zip file above and double-click to extract. You\u2019ll get WinKeys.app.",
            },
            {
              title: "Move to Applications",
              desc: "Drag WinKeys.app into your /Applications folder.",
            },
            {
              title: "Allow in macOS Security",
              desc: "When you first open WinKeys, macOS will show \u201cWinKeys can\u2019t be opened.\u201d This is normal for unsigned apps. Click \u201cDone\u201d, then go to System Settings > Privacy & Security, scroll down and click \u201cOpen Anyway\u201d next to the WinKeys message. Launch WinKeys again and click \u201cOpen\u201d.",
            },
            {
              title: "Grant Accessibility Permission",
              desc: "macOS will ask for Accessibility permission \u2014 this is required for keyboard remapping. Go to System Settings > Privacy & Security > Accessibility and enable WinKeys.",
            },
          ].map((step, i) => (
            <li key={i} className="flex gap-4">
              <div className="flex-shrink-0 w-8 h-8 rounded-full bg-[#0078D4] text-white flex items-center justify-center font-bold text-sm">
                {i + 1}
              </div>
              <div>
                <h4 className="font-semibold mb-1">{step.title}</h4>
                <p className="text-gray-600 text-sm">{step.desc}</p>
              </div>
            </li>
          ))}
        </ol>

        {/* Accessibility note */}
        <div className="mt-8 p-4 bg-amber-50 border border-amber-200 rounded-xl text-sm">
          <p className="font-semibold text-amber-800 mb-1">Accessibility Permission</p>
          <p className="text-amber-700">
            Go to <strong>System Settings &gt; Privacy &amp; Security &gt; Accessibility</strong> and
            enable WinKeys. If shortcuts don&apos;t work after an update, remove WinKeys from the
            list (−) and re-add it (+).
          </p>
        </div>
      </div>
    </section>
  );
}
