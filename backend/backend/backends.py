from microsoft_auth.backends import MicrosoftAuthenticationBackend as BaseMicrosoftAuthenticationBackend


class MicrosoftAuthenticationBackend(BaseMicrosoftAuthenticationBackend):

    def _verify_microsoft_user(self, microsoft_user, data):
        if 'email' not in data:
            data['email'] = data['preferred_username']

        return super()._verify_microsoft_user(microsoft_user, data)
