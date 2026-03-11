/* Minimal Firebase Messaging Service Worker for background web push.
 * Displays notifications for FCM payloads and navigates to tracking page when clicked.
 */
self.addEventListener('push', function (event) {
  let data = {};
  try {
    data = event.data ? event.data.json() : {};
  } catch (e) {}
  const notif = data.notification || {};
  const title = notif.title || 'Notifikasi';
  const options = {
    body: notif.body || '',
    icon: notif.icon || '/icons/Icon-192.png',
    badge: notif.badge || '/icons/Icon-192.png',
    data: data.data || {},
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  const d = event.notification.data || {};
  const orderId = d.order_id || d.orderId || d.orderID;
  let url = self.location.origin;
  if (orderId) {
    url += '/#/kofood/tracking/' + orderId;
  } else {
    url += '/#/';
  }
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clientsArr) {
      for (let i = 0; i < clientsArr.length; i++) {
        const client = clientsArr[i];
        if ('focus' in client) {
          client.focus();
          if ('navigate' in client) client.navigate(url);
          return;
        }
      }
      if (self.clients.openWindow) return self.clients.openWindow(url);
    })
  );
});
