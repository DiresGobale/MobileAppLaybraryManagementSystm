const {
  LibraryServiceModel,
  LibraryStepModel,
  ContactMessageModel,
} = require('../models/libraryModels');
const { SettingModel, ActivityLogModel } = require('../models/auxModels');
const { AppError } = require('../middleware/errorHandler');
const { ACTION_KEYS, SETTINGS_KEYS } = require('../config/constants');

class LibraryInfoService {
  // ---- Services ----
  listServices() {
    return LibraryServiceModel.all({ activeOnly: true });
  }
  listAllServices() {
    return LibraryServiceModel.all({ activeOnly: false });
  }
  createService(payload, { actorId = null } = {}) {
    const id = LibraryServiceModel.create({
      title: payload.title,
      description: payload.description,
      icon_name: payload.icon_name || 'menu_book',
      display_order: payload.display_order || 1,
    });
    ActivityLogModel.create({
      user_id: actorId,
      action: ACTION_KEYS.SERVICE_ADD,
      details: `Added service: ${payload.title}`,
    });
    return LibraryServiceModel.findById(id);
  }
  updateService(id, payload, { actorId = null } = {}) {
    LibraryServiceModel.update(id, {
      title: payload.title,
      description: payload.description,
      icon_name: payload.icon_name || 'menu_book',
      display_order: payload.display_order || 1,
      is_active: payload.is_active !== false,
    });
    ActivityLogModel.create({
      user_id: actorId,
      action: ACTION_KEYS.SERVICE_EDIT,
      details: `Updated service #${id}: ${payload.title}`,
    });
    return LibraryServiceModel.findById(id);
  }
  deleteService(id, { actorId = null } = {}) {
    const svc = LibraryServiceModel.findById(id);
    const title = svc?.title;
    LibraryServiceModel.remove(id);
    ActivityLogModel.create({
      user_id: actorId,
      action: ACTION_KEYS.SERVICE_DELETE,
      details: `Deleted service #${id}${title ? ` (${title})` : ''}`,
    });
  }

  // ---- Steps ----
  listSteps() {
    return LibraryStepModel.all({ activeOnly: true });
  }
  listAllSteps() {
    return LibraryStepModel.all({ activeOnly: false });
  }
  createStep(payload, { actorId = null } = {}) {
    const id = LibraryStepModel.create({
      step_number: payload.step_number,
      title: payload.title,
      description: payload.description,
      icon_name: payload.icon_name || 'search',
      display_order: payload.display_order || 1,
    });
    ActivityLogModel.create({
      user_id: actorId,
      action: ACTION_KEYS.STEP_ADD,
      details: `Added step: ${payload.title}`,
    });
    return LibraryStepModel.findById(id);
  }
  updateStep(id, payload, { actorId = null } = {}) {
    LibraryStepModel.update(id, {
      step_number: payload.step_number,
      title: payload.title,
      description: payload.description,
      icon_name: payload.icon_name || 'search',
      display_order: payload.display_order || 1,
      is_active: payload.is_active !== false,
    });
    ActivityLogModel.create({
      user_id: actorId,
      action: ACTION_KEYS.STEP_EDIT,
      details: `Updated step #${id}: ${payload.title}`,
    });
    return LibraryStepModel.findById(id);
  }
  deleteStep(id, { actorId = null } = {}) {
    const step = LibraryStepModel.findById(id);
    const title = step?.title;
    LibraryStepModel.remove(id);
    ActivityLogModel.create({
      user_id: actorId,
      action: ACTION_KEYS.STEP_DELETE,
      details: `Deleted step #${id}${title ? ` (${title})` : ''}`,
    });
  }

  // ---- Contact messages ----
  submitContactMessage({ name, email, subject, message }) {
    const id = ContactMessageModel.create({ name, email, subject, message });
    ActivityLogModel.create({
      user_id: null,
      action: ACTION_KEYS.CONTACT_RECEIVED,
      details: `Contact form: "${subject}" from ${name} <${email}>`,
    });
    return ContactMessageModel.findById(id);
  }
  listContactMessages({ unhandledOnly = false } = {}) {
    return ContactMessageModel.all({ unhandledOnly });
  }
  markContactHandled(id, { actorId = null } = {}) {
    ContactMessageModel.markHandled(id);
    ActivityLogModel.create({
      user_id: actorId,
      action: ACTION_KEYS.CONTACT_HANDLED,
      details: `Marked contact message #${id} as handled`,
    });
  }
  deleteContactMessage(id, { actorId = null } = {}) {
    ContactMessageModel.remove(id);
    ActivityLogModel.create({
      user_id: actorId,
      action: ACTION_KEYS.CONTACT_DELETED,
      details: `Deleted contact message #${id}`,
    });
  }

  // ---- Aggregated contact info ----
  fetchContactInfo() {
    const m = SettingModel.all();
    return {
      libraryName: m[SETTINGS_KEYS.LIBRARY_NAME] || 'Injibara University Library',
      tagline: m[SETTINGS_KEYS.LIBRARY_TAGLINE] || 'Knowledge · Heritage · Discovery',
      mission: m[SETTINGS_KEYS.LIBRARY_MISSION] || '',
      vision: m[SETTINGS_KEYS.LIBRARY_VISION] || '',
      history: m[SETTINGS_KEYS.LIBRARY_HISTORY] || '',
      email: m[SETTINGS_KEYS.CONTACT_EMAIL] || '',
      phone: m[SETTINGS_KEYS.CONTACT_PHONE] || '',
      address: m[SETTINGS_KEYS.CONTACT_ADDRESS] || '',
      hours: m[SETTINGS_KEYS.CONTACT_HOURS] || '',
      facebook: m[SETTINGS_KEYS.CONTACT_FACEBOOK] || null,
      twitter: m[SETTINGS_KEYS.CONTACT_TWITTER] || null,
      instagram: m[SETTINGS_KEYS.CONTACT_INSTAGRAM] || null,
    };
  }

  async setSetting(key, value, { actorId = null } = {}) {
    SettingModel.set(key, value);
    ActivityLogModel.create({
      user_id: actorId,
      action: ACTION_KEYS.LIBRARY_INFO_EDIT,
      details: `Updated setting "${key}"`,
    });
  }
}

module.exports = new LibraryInfoService();
