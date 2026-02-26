import Header from "@/components/Header";
import Hero from "@/components/Hero";
import Features from "@/components/Features";
import ShortcutManual from "@/components/ShortcutManual";
import Download from "@/components/Download";
import FAQ from "@/components/FAQ";
import FeedbackForm from "@/components/FeedbackForm";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <>
      <Header />
      <main>
        <Hero />
        <Features />
        <ShortcutManual />
        <Download />
        <FAQ />
        <FeedbackForm />
      </main>
      <Footer />
    </>
  );
}
