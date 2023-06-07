import sys
from datetime import datetime, timezone

from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth.hashers import make_password
from django.contrib.auth.models import User
from django.core.mail import send_mail
from django.db.utils import IntegrityError
from django.utils.crypto import get_random_string
from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .serializers import UserSerializer

User = get_user_model()


class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['name'] = user.name
        return token


class MyTokenObtainPairView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.filter(is_active=True)
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def register_user(self, request):
        """
        api to register user
        """
        verification_secret = get_random_string(length=32)

        if 'password' in request.data and 'email' in request.data and 'name' in request.data:
            try:
                user = User.objects.create_user(
                    email=request.data['email'],
                    name=request.data['name'],
                    password=request.data['password'],
                    is_active=False,
                    is_staff=False,
                    is_superuser=False,
                    sent_verification_email=False,
                    verified_email=False,
                    verification_email_secret=verification_secret,
                )
            except IntegrityError:
                return Response({'message': 'user already exists'}, status=status.HTTP_400_BAD_REQUEST)
            except:
                return Response({'message': 'user could not be registered'}, status=status.HTTP_400_BAD_REQUEST)

            try:
                send_mail(
                    f'Verify your user account for {settings.WEB_SITE_NAME}',
                    f'To verify your user account for {settings.WEB_SITE_NAME}, please go to {settings.VERIFICATION_URL}{verification_secret}',
                    settings.EMAIL_HOST_USER,
                    [request.data['email']],
                    fail_silently=False,
                    html_message=f'Please <a href="{settings.VERIFICATION_URL}{verification_secret}">click this link</a> to verify your user account for {settings.WEB_SITE_NAME}.',

                )
                user.sent_verification_email = True
                user.save()
            except:
                print("send_mail exception:", sys.exc_info())
                return Response({'message': 'Verification email could not be sent.'}, status=status.HTTP_400_BAD_REQUEST)
            return Response({'message': 'user registered'}, status=status.HTTP_200_OK)
        return Response({'message': 'user information missing'}, status=status.HTTP_400_BAD_REQUEST)

    def user_email_verify(self, request):
        try:
            verification_secret = request.data['verification_secret']
            user = User.objects.get(verification_email_secret=verification_secret)
            user.verified_email = True
            user.is_active = True
            user.date_email_verified = datetime.now(timezone.utc)
            user.save()
            return Response({'message': 'user verified'}, status=status.HTTP_200_OK)
        except:
            return Response({'message': 'unable to verify user'}, status=status.HTTP_400_BAD_REQUEST)

    def delete_user(self, request, *args, **kwargs):
        """
        :param request: to delete user
        :param args:
        :param kwargs:
        :return:
        """
        try:
            user = User.objects.get(email=request.user)
            user.is_active = False
            user.save()
            return Response({"message": "User data deleted successfully."}, status=status.HTTP_204_NO_CONTENT)
        except Exception as e:
            return Response({"message": "Error in deleting User."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def update_user_profile(self, request):
        """
        api to update user profile data
        """
        update_flag = False
        user = User.objects.get(email=request.user)
        if "name" in request.data:
            user.name = request.data['name']
            update_flag = True
        if "password" in request.data:
            user.password = make_password(request.data['password'])
            update_flag = True
        if update_flag:
            user.save()
        access_token = RefreshToken.for_user(user)
        access_token['name'] = user.name
        return Response({'access': str(access_token.access_token), 'refresh': str(access_token)}, status=status.HTTP_200_OK)

    def reset_password(self, request):
        """
        api to update user data and user profile data for given user id
        """
        if "password" not in request.data:
            return Response({"message": "Bad Request"}, status=status.HTTP_400_BAD_REQUEST)
        try:
            user = User.objects.get(reset_password_secret=request.data['reset_secret'])
            user.password = make_password(request.data['password'])
            user.reset_password_secret = None
            user.save()
        except:
            return Response(status=status.HTTP_400_BAD_REQUEST)
        return Response({"message": "User data fetched successfully."}, status=status.HTTP_200_OK)

    def forgot_password(self, request):

        if "email" in request.data:
            reset_secret = get_random_string(length=32)
            try:
                user = User.objects.get(email=request.data['email'])
                user.reset_password_secret = reset_secret
                user.save()
            except:
                return Response(status=status.HTTP_200_OK)
            try:
                send_mail(
                    f'Password reset for your account on {settings.WEB_SITE_NAME}',
                    f'To reset your password for {settings.WEB_SITE_NAME}, please go to {settings.RESET_PASSWORD_URL}{reset_secret}',
                    settings.EMAIL_HOST_USER,
                    [request.data['email']],
                    fail_silently=False,
                    html_message=f'Please <a href="{settings.RESET_PASSWORD_URL}{reset_secret}">click this link</a> to reset your password for {settings.WEB_SITE_NAME}.'
                )
            except:
                pass
            return Response({'message': 'please check email.'}, status=status.HTTP_200_OK)
        return Response(status=status.HTTP_400_BAD_REQUEST)

    def get_all_user(self, request, *args, **kwargs):
        """
        api to get list of all active user
        """
        try:
            users = User.objects.filter(is_active=True)
            serializer = UserSerializer(users, many=True)
            data = serializer.data
            return Response({"message": "Users data fetched successfully.", 'data': data}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"message": "Unable to fetch Users data."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
