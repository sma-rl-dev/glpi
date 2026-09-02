-- Deterministic tester-env GLPI seed profile: northwind-it-ops
-- Theme: Northwind internal IT operations with approvals, assets, projects, entities, planning, and ITIL ticket templates.

SET @now := '2026-01-15 09:00:00';

-- Clean only tester-env owned records so re-running seed is deterministic.
DELETE FROM glpi_ticketvalidations WHERE tickets_id IN (SELECT id FROM glpi_tickets WHERE name LIKE 'Seed:%');
DELETE FROM glpi_tickets_users WHERE tickets_id IN (SELECT id FROM glpi_tickets WHERE name LIKE 'Seed:%');
DELETE FROM glpi_groups_tickets WHERE tickets_id IN (SELECT id FROM glpi_tickets WHERE name LIKE 'Seed:%');
DELETE FROM glpi_items_tickets WHERE tickets_id IN (SELECT id FROM glpi_tickets WHERE name LIKE 'Seed:%');
DELETE FROM glpi_tickets WHERE name LIKE 'Seed:%';
DELETE FROM glpi_tickettemplatehiddenfields WHERE tickettemplates_id IN (SELECT id FROM glpi_tickettemplates WHERE name LIKE 'Seed:%');
DELETE FROM glpi_tickettemplatepredefinedfields WHERE tickettemplates_id IN (SELECT id FROM glpi_tickettemplates WHERE name LIKE 'Seed:%');
DELETE FROM glpi_tickettemplatemandatoryfields WHERE tickettemplates_id IN (SELECT id FROM glpi_tickettemplates WHERE name LIKE 'Seed:%');
DELETE FROM glpi_tickettemplatereadonlyfields WHERE tickettemplates_id IN (SELECT id FROM glpi_tickettemplates WHERE name LIKE 'Seed:%');
DELETE FROM glpi_itilcategories WHERE name LIKE 'Seed %';
DELETE FROM glpi_tickettemplates WHERE name LIKE 'Seed:%';
DELETE FROM glpi_projectteams WHERE projects_id IN (SELECT id FROM glpi_projects WHERE name LIKE 'Seed:%');
DELETE FROM glpi_projecttasks WHERE name LIKE 'Seed:%';
DELETE FROM glpi_projects WHERE name LIKE 'Seed:%';
DELETE FROM glpi_planningexternalevents WHERE name LIKE 'Seed:%';
DELETE FROM glpi_computers WHERE name LIKE 'Seed-%';
DELETE FROM glpi_groups_users WHERE groups_id IN (SELECT id FROM glpi_groups WHERE name LIKE 'Seed %') OR users_id IN (SELECT id FROM glpi_users WHERE name LIKE 'seed.%');
DELETE FROM glpi_profiles_users WHERE users_id IN (SELECT id FROM glpi_users WHERE name LIKE 'seed.%');
DELETE FROM glpi_users WHERE name LIKE 'seed.%';
DELETE FROM glpi_groups WHERE name LIKE 'Seed %';
DELETE FROM glpi_entities WHERE name LIKE 'Seed %';

-- Entities chosen so short-name sort and complete-name sort differ visibly.
INSERT INTO glpi_entities (name, entities_id, completename, comment, level, address, town, country, email, notification_subject_tag, tickettemplates_strategy, tickettemplates_id, date_creation, date_mod)
VALUES
  ('Seed Zeta Parent', 0, 'Seed Zeta Parent', 'Parent entity for inherited value display checks', 1, '100 Northwind Way', 'London', 'GB', 'it-ops@example.test', '[NW-ZETA]', 0, 0, @now, @now),
  ('Seed Alpha Child', (SELECT id FROM (SELECT id FROM glpi_entities WHERE name='Seed Zeta Parent' LIMIT 1) p), 'Seed Zeta Parent > Seed Alpha Child', 'Child entity inheriting parent notification tag/address', 2, NULL, NULL, NULL, NULL, NULL, -2, 0, @now, @now),
  ('Seed Beta Parent', 0, 'Seed Beta Parent', 'Second parent for entity list default sort', 1, '200 Northwind Way', 'Bristol', 'GB', 'ops-beta@example.test', '[NW-BETA]', 0, 0, @now, @now);

INSERT INTO glpi_groups (entities_id, is_recursive, name, code, comment, completename, level, is_requester, is_assign, date_creation, date_mod)
VALUES
  (0, 1, 'Seed Approval Board', 'SEED-APPROVAL', 'Group approvers for seeded validation tickets', 'Seed Approval Board', 1, 1, 1, @now, @now),
  (0, 1, 'Seed Field Support', 'SEED-FIELD', 'Technician group shown on dashboard widgets', 'Seed Field Support', 1, 1, 1, @now, @now);

INSERT INTO glpi_users (name, realname, firstname, language, is_active, authtype, profiles_id, entities_id, groups_id, comment, substitution_start_date, substitution_end_date, date_creation, date_mod)
VALUES
  ('seed.approver', 'Patel', 'Maya', 'en_GB', 1, 1, 6, 0, (SELECT id FROM glpi_groups WHERE name='Seed Approval Board'), 'Seed approval owner', '2026-01-01 00:00:00', '2026-12-31 23:59:59', @now, @now),
  ('seed.substitute', 'Reed', 'Noah', 'en_GB', 1, 1, 6, 0, (SELECT id FROM glpi_groups WHERE name='Seed Approval Board'), 'Seed approval substitute/delegate', NULL, NULL, @now, @now),
  ('seed.assetowner', 'Chen', 'Iris', 'en_GB', 1, 1, 2, 0, (SELECT id FROM glpi_groups WHERE name='Seed Field Support'), 'Seed user with multiple used assets', NULL, NULL, @now, @now),
  ('seed.projectmember', 'Okafor', 'Leo', 'en_GB', 1, 1, 6, 0, (SELECT id FROM glpi_groups WHERE name='Seed Field Support'), 'Seed project member', NULL, NULL, @now, @now);

INSERT INTO glpi_profiles_users (users_id, profiles_id, entities_id, is_recursive, is_default_profile)
SELECT id, profiles_id, 0, 1, 1 FROM glpi_users WHERE name LIKE 'seed.%';

INSERT INTO glpi_groups_users (users_id, groups_id, is_manager, is_userdelegate)
VALUES
  ((SELECT id FROM glpi_users WHERE name='seed.approver'), (SELECT id FROM glpi_groups WHERE name='Seed Approval Board'), 1, 0),
  ((SELECT id FROM glpi_users WHERE name='seed.substitute'), (SELECT id FROM glpi_groups WHERE name='Seed Approval Board'), 0, 1),
  ((SELECT id FROM glpi_users WHERE name='seed.assetowner'), (SELECT id FROM glpi_groups WHERE name='Seed Field Support'), 0, 0),
  ((SELECT id FROM glpi_users WHERE name='seed.projectmember'), (SELECT id FROM glpi_groups WHERE name='Seed Field Support'), 0, 0);

INSERT INTO glpi_computers (entities_id, name, serial, otherserial, users_id, users_id_tech, comment, date_creation, date_mod, is_recursive)
VALUES
  (0, 'Seed-Laptop-Iris-01', 'NW-LAP-001', 'ASSET-IRIS-LAPTOP', (SELECT id FROM glpi_users WHERE name='seed.assetowner'), (SELECT id FROM glpi_users WHERE name='seed.projectmember'), 'Primary laptop for used-items filtering', @now, @now, 1),
  (0, 'Seed-Tablet-Iris-02', 'NW-TAB-002', 'ASSET-IRIS-TABLET', (SELECT id FROM glpi_users WHERE name='seed.assetowner'), (SELECT id FROM glpi_users WHERE name='seed.projectmember'), 'Tablet for used-items filtering', @now, @now, 1);

-- Ticket templates for ITIL template checks: a standard intake template recorded on the seeded
-- ticket and a specialized hardware replacement template wired to its category for incidents.
-- Field nums (Ticket search options): 3=priority, 10=urgency, 11=impact.
INSERT INTO glpi_tickettemplates (name, entities_id, is_recursive, comment, allowed_statuses)
VALUES
  ('Seed: Standard Intake Template', 0, 1, 'Default intake template recorded on tickets logged through the standard flow.', '[1,10,2,3,4,5,6]'),
  ('Seed: Hardware Replacement Template', 0, 1, 'Hardware replacement flow: fixed priority values, no agent choice.', '[1,10,2,3,4,5,6]');

INSERT INTO glpi_tickettemplatepredefinedfields (tickettemplates_id, num, value)
VALUES
  ((SELECT id FROM glpi_tickettemplates WHERE name='Seed: Hardware Replacement Template'), 10, '3'),
  ((SELECT id FROM glpi_tickettemplates WHERE name='Seed: Hardware Replacement Template'), 11, '3'),
  ((SELECT id FROM glpi_tickettemplates WHERE name='Seed: Hardware Replacement Template'), 3, '4');

INSERT INTO glpi_tickettemplatehiddenfields (tickettemplates_id, num)
VALUES
  ((SELECT id FROM glpi_tickettemplates WHERE name='Seed: Hardware Replacement Template'), 3);

INSERT INTO glpi_itilcategories (entities_id, is_recursive, name, completename, comment, level, is_helpdeskvisible, tickettemplates_id_incident, tickettemplates_id_demand, is_incident, is_request, is_problem, is_change, date_mod, date_creation)
VALUES
  (0, 1, 'Seed Hardware Replacement', 'Seed Hardware Replacement', 'Hardware swap requests; incidents use the hardware replacement template.', 1, 1, (SELECT id FROM glpi_tickettemplates WHERE name='Seed: Hardware Replacement Template'), 0, 1, 1, 1, 1, @now, @now);

INSERT INTO glpi_tickets (entities_id, name, date, date_creation, date_mod, users_id_lastupdater, status, users_id_recipient, requesttypes_id, content, urgency, impact, priority, type, global_validation, itilcategories_id, tickettemplates_id)
VALUES
  (0, 'Seed: Approval needed for VPN concentrator', '2026-01-15 09:05:00', @now, @now, 2, 2, (SELECT id FROM glpi_users WHERE name='seed.assetowner'), 1, 'Approval workflow ticket visible to substitute and group approvers.', 3, 3, 3, 1, 2, 0, 0),
  (0, 'Seed: Replace Iris docking station', '2026-01-15 10:00:00', @now, @now, 2, 2, (SELECT id FROM glpi_users WHERE name='seed.assetowner'), 1, 'Editable ticket for save-and-navigate warning checks.', 2, 2, 2, 1, 1, (SELECT id FROM glpi_itilcategories WHERE name='Seed Hardware Replacement'), (SELECT id FROM glpi_tickettemplates WHERE name='Seed: Standard Intake Template')),
  (0, 'Seed: Field Support WiFi rollout', '2026-01-15 11:00:00', @now, @now, 2, 1, (SELECT id FROM glpi_users WHERE name='seed.projectmember'), 1, 'Dashboard group label/count source ticket.', 3, 2, 3, 1, 1, 0, 0);

INSERT INTO glpi_tickets_users (tickets_id, users_id, type)
SELECT id, (SELECT id FROM glpi_users WHERE name='seed.assetowner'), 1 FROM glpi_tickets WHERE name IN ('Seed: Approval needed for VPN concentrator', 'Seed: Replace Iris docking station')
UNION ALL SELECT id, (SELECT id FROM glpi_users WHERE name='seed.projectmember'), 2 FROM glpi_tickets WHERE name='Seed: Field Support WiFi rollout';

INSERT INTO glpi_groups_tickets (tickets_id, groups_id, type)
VALUES
  ((SELECT id FROM glpi_tickets WHERE name='Seed: Approval needed for VPN concentrator'), (SELECT id FROM glpi_groups WHERE name='Seed Approval Board'), 1),
  ((SELECT id FROM glpi_tickets WHERE name='Seed: Field Support WiFi rollout'), (SELECT id FROM glpi_groups WHERE name='Seed Field Support'), 2);

INSERT INTO glpi_ticketvalidations (entities_id, users_id, tickets_id, users_id_validate, itemtype_target, items_id_target, comment_submission, status, submission_date)
VALUES
  (0, 2, (SELECT id FROM glpi_tickets WHERE name='Seed: Approval needed for VPN concentrator'), (SELECT id FROM glpi_users WHERE name='seed.approver'), 'User', (SELECT id FROM glpi_users WHERE name='seed.approver'), 'Please approve VPN capacity increase.', 2, '2026-01-15 09:10:00'),
  (0, 2, (SELECT id FROM glpi_tickets WHERE name='Seed: Approval needed for VPN concentrator'), 0, 'Group', (SELECT id FROM glpi_groups WHERE name='Seed Approval Board'), 'Group approval for change window.', 2, '2026-01-15 09:15:00');

INSERT INTO glpi_items_tickets (itemtype, items_id, tickets_id)
VALUES
  ('Computer', (SELECT id FROM glpi_computers WHERE name='Seed-Laptop-Iris-01'), (SELECT id FROM glpi_tickets WHERE name='Seed: Replace Iris docking station')),
  ('Computer', (SELECT id FROM glpi_computers WHERE name='Seed-Tablet-Iris-02'), (SELECT id FROM glpi_tickets WHERE name='Seed: Replace Iris docking station'));

INSERT INTO glpi_projects (name, code, priority, entities_id, is_recursive, date, users_id, groups_id, plan_start_date, plan_end_date, percent_done, content, date_creation, date_mod)
VALUES ('Seed: Northwind WiFi Refresh', 'SEED-WIFI', 3, 0, 1, '2026-01-15 12:00:00', (SELECT id FROM glpi_users WHERE name='seed.projectmember'), (SELECT id FROM glpi_groups WHERE name='Seed Field Support'), '2026-02-01 09:00:00', '2026-03-15 17:00:00', 25, 'Project seeded for task visibility checks.', @now, @now);

INSERT INTO glpi_projectteams (projects_id, itemtype, items_id)
VALUES
  ((SELECT id FROM glpi_projects WHERE name='Seed: Northwind WiFi Refresh'), 'User', (SELECT id FROM glpi_users WHERE name='seed.projectmember')),
  ((SELECT id FROM glpi_projects WHERE name='Seed: Northwind WiFi Refresh'), 'Group', (SELECT id FROM glpi_groups WHERE name='Seed Field Support'));

INSERT INTO glpi_projecttasks (uuid, name, content, entities_id, is_recursive, projects_id, date_creation, date_mod, plan_start_date, plan_end_date, users_id, percent_done)
VALUES ('seed-project-task-wifi-survey', 'Seed: WiFi survey floor 3', 'Visible project task for allowed member/filter checks.', 0, 1, (SELECT id FROM glpi_projects WHERE name='Seed: Northwind WiFi Refresh'), @now, @now, '2026-02-03 09:00:00', '2026-02-03 17:00:00', (SELECT id FROM glpi_users WHERE name='seed.projectmember'), 10);

INSERT INTO glpi_planningexternalevents (uuid, entities_id, is_recursive, date, users_id, name, text, begin, end, state, date_creation, date_mod)
VALUES ('seed-planning-vendor-maintenance', 0, 1, '2026-01-16 09:00:00', (SELECT id FROM glpi_users WHERE name='seed.projectmember'), 'Seed: Vendor maintenance reminder', 'External maintenance event with stable date and owner.', '2026-01-20 10:00:00', '2026-01-20 11:00:00', 1, @now, @now);
