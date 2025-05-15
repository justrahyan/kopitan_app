class NotificationPreference {
  static bool isNotificationOn = true;

  static void setNotification(bool value) {
    isNotificationOn = value;
  }

  static bool getNotificationStatus() {
    return isNotificationOn;
  }
}
