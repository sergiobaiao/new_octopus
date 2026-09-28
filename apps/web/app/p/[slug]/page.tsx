import { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { IS_FORMBRICKS_CLOUD } from "@/lib/constants";
import { getSurveyBySlug } from "@/modules/survey/lib/slug";
import { getMetadataForLinkSurvey } from "@/modules/survey/link/metadata";

interface PrettyUrlPageProps {
  params: Promise<{ slug: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}

// Without this, link-preview crawlers (WhatsApp, Slack, etc.) that don't follow the redirect
// below to /s/[surveyId] fall through to the root layout's generic title/description instead of
// the survey's own branding (org whitelabel favicon, custom OG image, link metadata).
export const generateMetadata = async (props: PrettyUrlPageProps): Promise<Metadata> => {
  const { slug } = await props.params;
  const searchParams = await props.searchParams;

  if (IS_FORMBRICKS_CLOUD) {
    notFound();
  }

  const survey = await getSurveyBySlug(slug);
  if (!survey) {
    notFound();
  }

  const languageCode = typeof searchParams.lang === "string" ? searchParams.lang : undefined;
  return getMetadataForLinkSurvey(survey.id, languageCode);
};

export default async function PrettyUrlPage(props: PrettyUrlPageProps) {
  const { slug } = await props.params;
  const searchParams = await props.searchParams;

  if (IS_FORMBRICKS_CLOUD) {
    return notFound();
  }

  const survey = await getSurveyBySlug(slug);
  if (!survey) {
    return notFound();
  }

  // Preserve query params (suId, lang, etc.)
  const queryString = new URLSearchParams(
    Object.entries(searchParams).filter(([_, v]) => v !== undefined) as [string, string][]
  ).toString();

  const baseUrl = `/s/${survey.id}`;
  const redirectUrl = queryString ? `${baseUrl}?${queryString}` : baseUrl;

  redirect(redirectUrl);
}
