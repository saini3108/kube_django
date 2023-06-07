export const BACKEND_URL = "_env_" in window ? window._env_.BACKEND_URL : "http://localhost:8000/";

export const REGISTRATION_ENDPOINT = BACKEND_URL + "user_management/register_user/";

export const VERIFY_EMAIL_ENDPOINT = BACKEND_URL + "user_management/user_email_verify/";

export const LOGIN_ENDPOINT = BACKEND_URL + "user_management/token/";

export const DELETE_USER_ENDPOINT = BACKEND_URL + "user_management/delete_user/";

export const PROFILE_UPDATE_ENDPOINT = BACKEND_URL + "user_management/update_user_profile/";

export const FORGOT_PASSWORD_ENDPOINT = BACKEND_URL + "user_management/forgot_password/";

export const RESET_PASSWORD_ENDPOINT = BACKEND_URL + "user_management/reset_password/";
