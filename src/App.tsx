import { useQuery } from "convex/react";
import { api } from "../convex/_generated/api";

function App() {
  const greeting = useQuery(api.hello.get);

  return (
    <main>
      <h1>CAIRN starter</h1>
      <p>Convex says: {greeting ?? "loading…"}</p>
      <p>
        Edit <code>src/App.tsx</code> to start building. The harness (hooks, verify scripts, CI,
        branch protection) is already wired.
      </p>
    </main>
  );
}

export default App;
