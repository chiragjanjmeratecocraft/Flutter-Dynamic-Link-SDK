export interface IDynamicLinkResponse {
  name: string;
  description: string;
  short_code: string;
  custom_domain: null;
  params: Record<string, string>;
  projectId: string;
  android_scheme: string;
  ios_scheme: string;
  desktop_link: null;
  project: Project;
}
interface Project {
  id: string;
  name: string;
  description: string;
  on_playstore: boolean;
  on_appstore: boolean;
  android_package_name: string;
  ios_bundle_id: null;
  default_url: string;
  android_fallback_url: string;
  ios_fallback_url: string;
  android_host: null;
  ios_host: null;
}
export interface ISmartLinkingOptions {
  onSuccess?: (data: IDynamicLinkResponse) => void;
  onError?: (error: Error) => void;
  onUrl?: (url: string) => void;
}