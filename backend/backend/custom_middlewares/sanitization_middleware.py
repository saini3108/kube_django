import os
import re
from django.contrib.sessions.models import Session
from django.db.models import Q
from django.utils import timezone


class SanitizeReqRes(object):
    def __init__(self, get_response):
        self.get_response = get_response

    @staticmethod
    def process_request_data(data):
        data = dict(data)
        if len(data) > 0:
            for key, value in data.items():
                data[key] = re.sub("\W+", "", value[0]) if value[0] else None
        return data

    def __call__(self, request):
        response = self.get_response(request)
        response['Server'] = "Chimera 1.0"
        response['Pragma'] = 'no-cache'
        response['Cache-Control'] = 'no-cache must-revalidate proxy-revalidate'
        if request.method in ["OPTIONS", "DELETE", "LOCK", "PUT", "UNLOCK"]:
            response.status_code = 403
        response.content = "Method not allowed" if response.status_code == 403 else response.content
        if request.content_type not in ["text/plain", "multipart/form-data",
                                        "application/x-www-form-urlencoded", "application/json"]:
            response.status_code = 400
        response.content = "Check content_type " if response.status_code == 400 else response.content
        # used to log user's `firstname`
        os.environ["USERID"] = str(request.user)
        data = request.GET if request.method == "GET" else request.POST
        if data:
            data = self.process_request_data(data)
        if request.method == "GET":
            request.GET = data
        else:
            request.POST = data
        # Ensure at a time single session is active
        for session in Session.objects.filter(~Q(session_key=request.session.session_key), expire_date__gte=timezone.now()):
            data = session.get_decoded()
            if data.get('_auth_user_id', None) == str(request.user.id):
                # found duplicate session, expire it
                session.expire_date = timezone.now()
                session.save()
        return response
