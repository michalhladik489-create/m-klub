import { SiteShell } from "@/components/SiteShell";
import { getPublished } from "@/lib/data";
import { todayPrague } from "@/lib/env";
import { renderPath } from "@/lib/views";

export default async function NotFound() {
  const s = await getPublished();
  const r = renderPath(["__neexistuje"], s, { base: "", edit: false, today: todayPrague() });
  return <SiteShell s={s} base="" active="" html={r.html} />;
}
