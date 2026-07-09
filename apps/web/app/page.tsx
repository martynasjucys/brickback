// Marketing site placeholder. The full landing page is Phase 8
// (docs/phases/08-marketing-site.md).

const STEPS = [
  { n: "1", title: "Select a set", body: "Search by set number or name." },
  { n: "2", title: "Collect the inventory", body: "Tap parts to count what you have." },
  { n: "3", title: "Review results", body: "See exactly which parts are missing." },
  { n: "4", title: "Finish", body: "Verify completion and export the rest." },
];

export default function Home() {
  return (
    <main className="mx-auto flex min-h-screen max-w-3xl flex-col justify-center px-6 py-20">
      <span className="mb-4 inline-flex w-fit items-center rounded-full border border-zinc-300 px-3 py-1 text-xs font-medium text-zinc-500">
        Coming soon
      </span>
      <h1 className="text-4xl font-bold tracking-tight text-zinc-900 sm:text-5xl">
        BrickBack
      </h1>
      <p className="mt-3 text-lg text-zinc-600">
        Bring LEGO® sets back from a pile of bricks.
      </p>
      <p className="mt-4 max-w-xl text-zinc-500">
        Rebuild complete sets from mixed or second-hand collections — count the
        parts you have, see what&apos;s missing, and verify completion.
      </p>

      <ol className="mt-10 grid grid-cols-1 gap-3 sm:grid-cols-2">
        {STEPS.map((s) => (
          <li
            key={s.n}
            className="rounded-xl border border-zinc-200 bg-white p-4"
          >
            <div className="flex items-center gap-2">
              <span className="flex h-6 w-6 items-center justify-center rounded-full bg-zinc-900 text-xs font-bold text-white">
                {s.n}
              </span>
              <span className="font-semibold text-zinc-900">{s.title}</span>
            </div>
            <p className="mt-2 text-sm text-zinc-500">{s.body}</p>
          </li>
        ))}
      </ol>

      <p className="mt-10 text-xs text-zinc-400">
        LEGO® is a trademark of the LEGO Group, which does not sponsor, authorize
        or endorse this project.
      </p>
    </main>
  );
}
