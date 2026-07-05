const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

async function getMemberTokens(familyId, excludeMemberId) {
  const members = await admin.firestore()
    .collection('members')
    .where('familyId', '==', familyId)
    .get();
  const tokens = [];
  for (const doc of members.docs) {
    if (doc.id === excludeMemberId) continue;
    const tokenDoc = await admin.firestore()
      .collection('fcm_tokens').doc(doc.id).get();
    if (tokenDoc.exists) tokens.push(tokenDoc.data().token);
  }
  return tokens;
}

exports.onSosAlert = functions.firestore
  .document('sos_alerts/{alertId}')
  .onCreate(async (snap, context) => {
    const alert = snap.data();
    const tokens = await getMemberTokens(alert.familyId, alert.memberId);
    const message = {
      notification: {
        title: 'SOS Alert!',
        body: `Family member needs help! Location: ${alert.lat},${alert.lng}`
      },
      data: { type: 'sos', alertId: context.params.alertId }
    };
    await admin.messaging().sendEachForMulticast({ tokens, ...message });
  });

exports.onGeofenceEvent = functions.firestore
  .document('geofence_events/{eventId}')
  .onCreate(async (snap, context) => {
    const event = snap.data();
    const tokens = await getMemberTokens(event.familyId, null);
    const message = {
      notification: {
        title: 'Geofence Alert',
        body: `${event.memberName} ${event.event === 'entered' ? 'arrived at' : 'left'} ${event.fenceName}`
      },
      data: { type: 'geofence' }
    };
    await admin.messaging().sendEachForMulticast({ tokens, ...message });
  });

exports.onLowBattery = functions.firestore
  .document('members/{memberId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data().batteryLevel;
    const after = change.after.data().batteryLevel;
    if (after > 20 || before <= 20) return null;
    const member = change.after.data();
    const tokens = await getMemberTokens(member.familyId, context.params.memberId);
    const message = {
      notification: {
        title: 'Low Battery',
        body: `${member.name}'s battery is at ${after}%`
      },
      data: { type: 'low_battery' }
    };
    await admin.messaging().sendEachForMulticast({ tokens, ...message });
  });
