const { NotificationModel, ActivityLogModel } = require('../models/auxModels');

class NotificationService {
  forUser(userId, { unreadOnly = false } = {}) {
    return NotificationModel.forUser(userId, { unreadOnly });
  }
  countUnread(userId) {
    return NotificationModel.countUnread(userId);
  }
  markRead(id) {
    return NotificationModel.markRead(id);
  }
  markAllRead(userId) {
    return NotificationModel.markAllRead(userId);
  }
  remove(id) {
    return NotificationModel.remove(id);
  }
}

class ActivityLogService {
  recent({ limit = 200, actorId = null } = {}) {
    return ActivityLogModel.recent({ limit, actorId });
  }
  countToday() {
    return ActivityLogModel.countToday();
  }
}

module.exports = { NotificationService: new NotificationService(), ActivityLogService: new ActivityLogService() };
