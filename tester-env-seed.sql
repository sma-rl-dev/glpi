-- Deterministic tester-env GLPI seed profile: northwind-it-ops
-- Theme: Northwind internal IT operations with approvals, assets, projects, entities, planning, and ITIL ticket templates.

SET @now := '2026-01-15 09:00:00';

-- Dashboards must reflect the business records rather than placeholder demo data.
UPDATE glpi_configs SET value = '0' WHERE context = 'core' AND name = 'is_demo_dashboards';

-- Clean only tester-env owned records so re-running seed is deterministic.
DELETE FROM glpi_ticketvalidations WHERE tickets_id IN (SELECT id FROM glpi_tickets WHERE name IN ('Approval needed for VPN concentrator', 'Replace Iris docking station', 'Field Support WiFi rollout'));
DELETE FROM glpi_tickets_users WHERE tickets_id IN (SELECT id FROM glpi_tickets WHERE name IN ('Approval needed for VPN concentrator', 'Replace Iris docking station', 'Field Support WiFi rollout'));
DELETE FROM glpi_groups_tickets WHERE tickets_id IN (SELECT id FROM glpi_tickets WHERE name IN ('Approval needed for VPN concentrator', 'Replace Iris docking station', 'Field Support WiFi rollout'));
DELETE FROM glpi_items_tickets WHERE tickets_id IN (SELECT id FROM glpi_tickets WHERE name IN ('Approval needed for VPN concentrator', 'Replace Iris docking station', 'Field Support WiFi rollout'));
DELETE FROM glpi_tickets WHERE name IN ('Approval needed for VPN concentrator', 'Replace Iris docking station', 'Field Support WiFi rollout');
DELETE FROM glpi_tickettemplatehiddenfields WHERE tickettemplates_id IN (SELECT id FROM glpi_tickettemplates WHERE name IN ('Standard Intake Template', 'Hardware Replacement Template'));
DELETE FROM glpi_tickettemplatepredefinedfields WHERE tickettemplates_id IN (SELECT id FROM glpi_tickettemplates WHERE name IN ('Standard Intake Template', 'Hardware Replacement Template'));
DELETE FROM glpi_tickettemplatemandatoryfields WHERE tickettemplates_id IN (SELECT id FROM glpi_tickettemplates WHERE name IN ('Standard Intake Template', 'Hardware Replacement Template'));
DELETE FROM glpi_tickettemplatereadonlyfields WHERE tickettemplates_id IN (SELECT id FROM glpi_tickettemplates WHERE name IN ('Standard Intake Template', 'Hardware Replacement Template'));
DELETE FROM glpi_itilcategories WHERE name = 'Hardware Replacement';
DELETE FROM glpi_tickettemplates WHERE name IN ('Standard Intake Template', 'Hardware Replacement Template');
DELETE FROM glpi_projectteams WHERE projects_id IN (SELECT id FROM glpi_projects WHERE name = 'Northwind WiFi Refresh');
DELETE FROM glpi_projecttasks WHERE name = 'WiFi survey floor 3';
DELETE FROM glpi_projects WHERE name = 'Northwind WiFi Refresh';
DELETE FROM glpi_planningexternalevents WHERE name = 'Vendor maintenance reminder';
DELETE FROM glpi_computers WHERE name IN ('NW-Laptop-Iris-01', 'NW-Tablet-Iris-02');
DELETE FROM glpi_groups_users WHERE groups_id IN (SELECT id FROM glpi_groups WHERE name IN ('Approval Board', 'Field Support')) OR users_id IN (SELECT id FROM glpi_users WHERE name IN ('maya.patel', 'noah.reed', 'iris.chen', 'leo.okafor'));
DELETE FROM glpi_profiles_users WHERE users_id IN (SELECT id FROM glpi_users WHERE name IN ('maya.patel', 'noah.reed', 'iris.chen', 'leo.okafor'));
DELETE FROM glpi_validatorsubstitutes WHERE users_id IN (SELECT id FROM glpi_users WHERE name IN ('maya.patel', 'noah.reed', 'iris.chen', 'leo.okafor')) OR users_id_substitute IN (SELECT id FROM glpi_users WHERE name IN ('maya.patel', 'noah.reed', 'iris.chen', 'leo.okafor'));
DELETE FROM glpi_profilerights WHERE profiles_id = 100;
DELETE FROM glpi_profiles WHERE id = 100 AND name = 'Approval Substitute';
DELETE FROM glpi_users WHERE name IN ('maya.patel', 'noah.reed', 'iris.chen', 'leo.okafor');
DELETE FROM glpi_groups WHERE name IN ('Approval Board', 'Field Support');
DELETE FROM glpi_entities WHERE name IN ('Zeta Division', 'Alpha Service Centre', 'Beta Division');

-- Entities chosen so short-name sort and complete-name sort differ visibly.
INSERT INTO glpi_entities (name, entities_id, completename, comment, level, address, town, country, email, notification_subject_tag, tickettemplates_strategy, tickettemplates_id, date_creation, date_mod)
VALUES
  ('Zeta Division', 0, 'Zeta Division', 'London regional IT operations', 1, '100 Northwind Way', 'London', 'GB', 'it-ops@example.test', '[NW-ZETA]', 0, 0, @now, @now),
  ('Alpha Service Centre', (SELECT id FROM (SELECT id FROM glpi_entities WHERE name='Zeta Division' LIMIT 1) p), 'Zeta Division > Alpha Service Centre', 'Service centre using regional notification settings', 2, NULL, NULL, NULL, NULL, NULL, -2, 0, @now, @now),
  ('Beta Division', 0, 'Beta Division', 'Bristol regional IT operations', 1, '200 Northwind Way', 'Bristol', 'GB', 'ops-beta@example.test', '[NW-BETA]', 0, 0, @now, @now);

INSERT INTO glpi_groups (entities_id, is_recursive, name, code, comment, completename, level, is_requester, is_assign, date_creation, date_mod)
VALUES
  (0, 1, 'Approval Board', 'NW-APPROVAL', 'Approvers for Northwind infrastructure changes', 'Approval Board', 1, 1, 1, @now, @now),
  (0, 1, 'Field Support', 'NW-FIELD', 'Technicians supporting regional offices', 'Field Support', 1, 1, 1, @now, @now);

-- Keep the substitute unable to see all or group-assigned tickets, so the
-- approval ticket is visible only through the authorized substitute relation.
INSERT INTO glpi_profiles (id, name, interface, comment, last_rights_update)
VALUES (100, 'Approval Substitute', 'central', 'Delegated approval role with validation-only ticket visibility.', @now);
INSERT INTO glpi_profilerights (profiles_id, name, rights)
SELECT 100, name, rights FROM glpi_profilerights WHERE profiles_id = 6;
UPDATE glpi_profilerights SET rights = 163847 WHERE profiles_id = 100 AND name = 'ticket';
UPDATE glpi_profilerights SET rights = 15376 WHERE profiles_id = 100 AND name = 'ticketvalidation';

INSERT INTO glpi_users (name, realname, firstname, language, is_active, authtype, profiles_id, entities_id, groups_id, comment, substitution_start_date, substitution_end_date, date_creation, date_mod)
VALUES
  ('maya.patel', 'Patel', 'Maya', 'en_GB', 1, 1, 6, 0, (SELECT id FROM glpi_groups WHERE name='Approval Board'), 'Approval owner and validator; delegates to authorized substitute.', NULL, NULL, @now, @now),
  ('noah.reed', 'Reed', 'Noah', 'en_GB', 1, 1, 100, 0, 0, 'Approval substitute with validation-only visibility.', NULL, NULL, @now, @now),
  ('iris.chen', 'Chen', 'Iris', 'en_GB', 1, 1, 2, 0, (SELECT id FROM glpi_groups WHERE name='Field Support'), 'Regional office laptop and tablet owner', NULL, NULL, @now, @now),
  ('leo.okafor', 'Okafor', 'Leo', 'en_GB', 1, 1, 6, 0, (SELECT id FROM glpi_groups WHERE name='Field Support'), 'WiFi refresh project technician', NULL, NULL, @now, @now);

INSERT INTO glpi_profiles_users (users_id, profiles_id, entities_id, is_recursive, is_default_profile)
SELECT id, profiles_id, 0, 1, 1 FROM glpi_users WHERE name IN ('maya.patel', 'noah.reed', 'iris.chen', 'leo.okafor');

INSERT INTO glpi_groups_users (users_id, groups_id, is_manager, is_userdelegate)
VALUES
  ((SELECT id FROM glpi_users WHERE name='maya.patel'), (SELECT id FROM glpi_groups WHERE name='Approval Board'), 1, 0),
  ((SELECT id FROM glpi_users WHERE name='iris.chen'), (SELECT id FROM glpi_groups WHERE name='Field Support'), 0, 0),
  ((SELECT id FROM glpi_users WHERE name='leo.okafor'), (SELECT id FROM glpi_groups WHERE name='Field Support'), 0, 0);

INSERT INTO glpi_computers (entities_id, name, serial, otherserial, users_id, users_id_tech, comment, date_creation, date_mod, is_recursive)
VALUES
  (0, 'NW-Laptop-Iris-01', 'NW-LAP-001', 'ASSET-IRIS-LAPTOP', (SELECT id FROM glpi_users WHERE name='iris.chen'), (SELECT id FROM glpi_users WHERE name='leo.okafor'), 'Iris Chen primary office laptop', @now, @now, 1),
  (0, 'NW-Tablet-Iris-02', 'NW-TAB-002', 'ASSET-IRIS-TABLET', (SELECT id FROM glpi_users WHERE name='iris.chen'), (SELECT id FROM glpi_users WHERE name='leo.okafor'), 'Iris Chen field service tablet', @now, @now, 1);

-- Ticket templates for ITIL template checks: a standard intake template recorded on the seeded
-- ticket and a specialized hardware replacement template wired to its category for incidents.
-- Field nums (Ticket search options): 3=priority, 10=urgency, 11=impact.
INSERT INTO glpi_tickettemplates (name, entities_id, is_recursive, comment, allowed_statuses)
VALUES
  ('Standard Intake Template', 0, 1, 'Default intake template recorded on tickets logged through the standard flow.', '[1,10,2,3,4,5,6]'),
  ('Hardware Replacement Template', 0, 1, 'Hardware replacement flow: fixed priority values, no agent choice.', '[1,10,2,3,4,5,6]');

INSERT INTO glpi_tickettemplatepredefinedfields (tickettemplates_id, num, value)
VALUES
  ((SELECT id FROM glpi_tickettemplates WHERE name='Hardware Replacement Template'), 10, '3'),
  ((SELECT id FROM glpi_tickettemplates WHERE name='Hardware Replacement Template'), 11, '3'),
  ((SELECT id FROM glpi_tickettemplates WHERE name='Hardware Replacement Template'), 3, '4');

INSERT INTO glpi_tickettemplatehiddenfields (tickettemplates_id, num)
VALUES
  ((SELECT id FROM glpi_tickettemplates WHERE name='Hardware Replacement Template'), 3);

INSERT INTO glpi_itilcategories (entities_id, is_recursive, name, completename, comment, level, is_helpdeskvisible, tickettemplates_id_incident, tickettemplates_id_demand, is_incident, is_request, is_problem, is_change, date_mod, date_creation)
VALUES
  (0, 1, 'Hardware Replacement', 'Hardware Replacement', 'Hardware swap requests; incidents use the hardware replacement template.', 1, 1, (SELECT id FROM glpi_tickettemplates WHERE name='Hardware Replacement Template'), 0, 1, 1, 1, 1, @now, @now);

INSERT INTO glpi_tickets (entities_id, name, date, date_creation, date_mod, users_id_lastupdater, status, users_id_recipient, requesttypes_id, content, urgency, impact, priority, type, global_validation, itilcategories_id, tickettemplates_id)
VALUES
  (0, 'Approval needed for VPN concentrator', '2026-01-15 09:05:00', @now, @now, 2, 2, (SELECT id FROM glpi_users WHERE name='iris.chen'), 1, 'VPN capacity increase requires approval before the change window.', 3, 3, 3, 1, 2, 0, 0),
  (0, 'Replace Iris docking station', '2026-01-15 10:00:00', @now, @now, 2, 2, (SELECT id FROM glpi_users WHERE name='iris.chen'), 1, 'Iris docking station disconnects displays during normal office work.', 2, 2, 2, 1, 1, (SELECT id FROM glpi_itilcategories WHERE name='Hardware Replacement'), (SELECT id FROM glpi_tickettemplates WHERE name='Standard Intake Template')),
  (0, 'Field Support WiFi rollout', '2026-01-15 11:00:00', @now, @now, 2, 1, (SELECT id FROM glpi_users WHERE name='leo.okafor'), 1, 'Coordinate wireless access point deployment across the regional offices.', 3, 2, 3, 1, 1, 0, 0);

INSERT INTO glpi_tickets_users (tickets_id, users_id, type)
SELECT id, (SELECT id FROM glpi_users WHERE name='iris.chen'), 1 FROM glpi_tickets WHERE name IN ('Approval needed for VPN concentrator', 'Replace Iris docking station')
UNION ALL SELECT id, (SELECT id FROM glpi_users WHERE name='leo.okafor'), 2 FROM glpi_tickets WHERE name='Field Support WiFi rollout';

INSERT INTO glpi_groups_tickets (tickets_id, groups_id, type)
VALUES
  ((SELECT id FROM glpi_tickets WHERE name='Approval needed for VPN concentrator'), (SELECT id FROM glpi_groups WHERE name='Approval Board'), 1),
  ((SELECT id FROM glpi_tickets WHERE name='Field Support WiFi rollout'), (SELECT id FROM glpi_groups WHERE name='Field Support'), 2);

INSERT INTO glpi_ticketvalidations (entities_id, users_id, tickets_id, users_id_validate, itemtype_target, items_id_target, comment_submission, status, submission_date)
VALUES
  (0, 2, (SELECT id FROM glpi_tickets WHERE name='Approval needed for VPN concentrator'), (SELECT id FROM glpi_users WHERE name='maya.patel'), 'User', (SELECT id FROM glpi_users WHERE name='maya.patel'), 'Please approve VPN capacity increase.', 2, '2026-01-15 09:10:00'),
  (0, 2, (SELECT id FROM glpi_tickets WHERE name='Approval needed for VPN concentrator'), 0, 'Group', (SELECT id FROM glpi_groups WHERE name='Approval Board'), 'Group approval for change window.', 2, '2026-01-15 09:15:00');

INSERT INTO glpi_validatorsubstitutes (users_id, users_id_substitute)
VALUES ((SELECT id FROM glpi_users WHERE name='maya.patel'), (SELECT id FROM glpi_users WHERE name='noah.reed'));

INSERT INTO glpi_items_tickets (itemtype, items_id, tickets_id)
VALUES
  ('Computer', (SELECT id FROM glpi_computers WHERE name='NW-Laptop-Iris-01'), (SELECT id FROM glpi_tickets WHERE name='Replace Iris docking station')),
  ('Computer', (SELECT id FROM glpi_computers WHERE name='NW-Tablet-Iris-02'), (SELECT id FROM glpi_tickets WHERE name='Replace Iris docking station'));

INSERT INTO glpi_projects (name, code, priority, entities_id, is_recursive, date, users_id, groups_id, plan_start_date, plan_end_date, percent_done, content, date_creation, date_mod)
VALUES ('Northwind WiFi Refresh', 'NW-WIFI', 3, 0, 1, '2026-01-15 12:00:00', (SELECT id FROM glpi_users WHERE name='leo.okafor'), (SELECT id FROM glpi_groups WHERE name='Field Support'), '2026-02-01 09:00:00', '2026-03-15 17:00:00', 25, 'Refresh regional office wireless coverage and access points.', @now, @now);

INSERT INTO glpi_projectteams (projects_id, itemtype, items_id)
VALUES
  ((SELECT id FROM glpi_projects WHERE name='Northwind WiFi Refresh'), 'User', (SELECT id FROM glpi_users WHERE name='leo.okafor')),
  ((SELECT id FROM glpi_projects WHERE name='Northwind WiFi Refresh'), 'Group', (SELECT id FROM glpi_groups WHERE name='Field Support'));

INSERT INTO glpi_projecttasks (uuid, name, content, entities_id, is_recursive, projects_id, date_creation, date_mod, plan_start_date, plan_end_date, users_id, percent_done)
VALUES ('northwind-project-task-wifi-survey', 'WiFi survey floor 3', 'Measure floor 3 wireless coverage before installing the new access points.', 0, 1, (SELECT id FROM glpi_projects WHERE name='Northwind WiFi Refresh'), @now, @now, '2026-02-03 09:00:00', '2026-02-03 17:00:00', (SELECT id FROM glpi_users WHERE name='leo.okafor'), 10);

INSERT INTO glpi_planningexternalevents (uuid, entities_id, is_recursive, date, users_id, name, text, begin, end, state, date_creation, date_mod)
VALUES ('northwind-planning-vendor-maintenance', 0, 1, '2026-01-16 09:00:00', (SELECT id FROM glpi_users WHERE name='leo.okafor'), 'Vendor maintenance reminder', 'Vendor maintenance window for the regional network equipment.', '2026-01-20 10:00:00', '2026-01-20 11:00:00', 1, @now, @now);
