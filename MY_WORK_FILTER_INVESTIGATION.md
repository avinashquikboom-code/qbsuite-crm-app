# Production My Work filters — 2026-10-11

Confirmed employee-side defect: overlapping requests could publish responses out of order. The selected filter changed immediately, but an older request could overwrite activities, filtered count, loading/error state and metrics after a newer request completed. This is a verified code defect; its occurrence in the reported screenshot has not been established without that employee's authenticated session.

## Flow and date semantics

`employee_ssm_work_list_view.dart` renders the Production Overview/My Work date controls. Today, Tomorrow and This Week call `setDateRangeFilter`; Pick Date calls `setDate`. The list and filtered-item count both use `EmployeeMyWorkState.activities`; the view does not perform a second date filter.

`EmployeeMyWorkNotifier._fetchDataForCurrentFilter` calls `/works/employee/calendar` with the selected customer/employee/team/status plus date parameters. `/works/production/metrics` deliberately receives customer/employee/team only. Its totals span the authorized work independently of date/status selection. Total 12 and Pending 10 therefore do not prove a Tomorrow result should be nonempty. Existing semantics are preserved.

| Control | Calendar parameters (October 11, 2026 reference date) |
| --- | --- |
| Today | `date=2026-10-11` |
| Tomorrow | `date=2026-10-12` |
| This Week | `dateFrom=2026-10-05&dateTo=2026-10-11` |
| Pick Date | `date=YYYY-MM-DD` for the selected day |
| All | No date parameters |

Week boundaries are Monday through Sunday. Flutter computes current-day presets from device-local date, preserving the existing app convention. No timezone or date-generation behavior changed.

`WorkController.getEmployeeCalendar` normalizes the query and resolves the employee/permissions. `WorkService.getEmployeeCalendar` filters Work by `scheduledDate`; standalone Task rows use `dueDate`, `startDate` or `dueAt`. WorkTask rows remain nested under Work. Prisma windows are deliberately buffered; the final comparison uses IST calendar dates (UTC +05:30), with inclusive day/range keys. Existing tests verify the IST midnight boundary and exclusion of other categories/tenants. No verified backend date-query defect was found, and no backend runtime code changed.

## Minimum fix and exact changed files

- `lib/roles/employee/viewmodels/employee_my_work_viewmodel.dart`: snapshot filter state for each request; increment a request version; ignore stale authentication completions, responses and failures; invalidate pending versions on disposal. An overridable clock preserves DateTime.now in production while making date tests deterministic.
- `test/employee_my_work_filters_test.dart`: new notifier/API regression tests for all preset parameters, Pick Date/refresh, genuine empty results/global metrics, out-of-order success/failure and repeated switching.
- Backend `src/modules/work/employee-designation-calendar.spec.ts`: added existing-fixture coverage for both sides of IST midnight, Monday–Sunday range, next-day results, nonmatching dates, designation and tenant exclusion.
- This report.

Customer purchasing, activation, schedule generation, calendar behavior, stored dates, assignments, task status and tenant/category visibility rules were not changed. No database writes, dummy production tasks or migrations were used. Synthetic test fixtures are not production evidence.

## Existing database dates

Read-only PrismaClient transaction inspected stored Work IDs, statuses, assignment IDs, categories and dates; no service startup or calendar-side sync/carry-forward ran. Local existing Work #2 is EDITING, SCHEDULED, unassigned, `2026-10-12T04:30:00.000Z` (October 12 at 10:00 IST). Additional editing Work #5, #8 and #11 are scheduled October 14, 22 and 30. Therefore local editing work exists tomorrow relative to October 11; this does not verify eligibility for the screenshot's employee. The earlier local inspection had no Video Editor employee profile, and the affected production environment/session is unavailable.

## Validation

- `flutter test test/employee_my_work_filters_test.dart`: 4 passed.
- Jest `employee-designation-calendar.spec.ts` and `customer-schedule-employee-visibility.spec.ts`: 2 suites / 19 tests passed.
- Targeted Flutter analysis of changed Dart files: no issues.
- Dart formatting and repository diff checks passed.
- Broader run including `employee_my_work_redesign_test.dart`: 8 passed, 2 failed on existing card/header expectations (including expecting a `My Work` text widget). Those UI assertions were not changed as part of this filter fix; that suite is not green.

Today, Tomorrow, This Week and Pick Date query construction is verified with deterministic notifier tests. Backend date/category/tenant behavior is verified with mocked existing test fixtures, including IST midnight. Authenticated production API results and the screenshot's expected task IDs remain unverified. Production verification is blocked on the affected employee/session and environment; no production success is claimed.
