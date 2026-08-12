import { ImageResponse } from "next/og";

// Generic site-wide link-preview image (used by the root layout's default openGraph/twitter
// metadata, e.g. when a page has no survey-specific og:image of its own). Deliberately separate
// from /api/v1/client/og, which renders the survey-invite card (with its "Begin!" CTA) and isn't
// appropriate as a generic site image.
export const GET = async () => {
  return new ImageResponse(
    (
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          width: "100%",
          height: "100%",
          backgroundImage: "linear-gradient(135deg, #1a2953 0%, #1f76bc 55%, #00c0ee 100%)",
        }}>
        <div
          style={{
            display: "flex",
            fontSize: "5rem",
            fontWeight: 700,
            color: "white",
            letterSpacing: "-0.02em",
          }}>
          Octopus
        </div>
        <div
          style={{
            display: "flex",
            marginTop: "1.5rem",
            fontSize: "2rem",
            fontWeight: 400,
            color: "rgba(255, 255, 255, 0.85)",
          }}>
          Sistema de Coleta de Dados da PGE-PI
        </div>
      </div>
    ),
    {
      width: 1200,
      height: 630,
      headers: {
        "Cache-Control": "public, s-maxage=600, max-age=1800, stale-while-revalidate=600, stale-if-error=600",
      },
    }
  );
};
