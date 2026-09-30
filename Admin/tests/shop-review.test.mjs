import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createRequire} from 'node:module';
import {runInNewContext} from 'node:vm';
import React from 'react';
import {renderToStaticMarkup} from 'react-dom/server';
import ts from 'typescript';

const require = createRequire(import.meta.url);
const element = (tag) => ({children, disabled}) => React.createElement(tag, {disabled}, children);
const mui = Object.fromEntries(['Dialog', 'DialogTitle', 'DialogContent', 'DialogActions', 'Stack', 'Typography', 'Box', 'Alert', 'CircularProgress', 'LinearProgress', 'TextField', 'MenuItem'].map((name) => [name, element('div')]));
mui.Button = element('button');
const shop = {id: 'shop-1', name: 'Owner wash', status: 'pending_review', updatedAt: {seconds: 1}};
const ready = {complete: true, issues: [], serviceCount: 1, availabilityDates: ['2026-10-02']};

function renderReview({onboarding = ready, isFetching = false, error = null, currentShop = shop, captureMutation, request} = {}) {
  function compile(relative) {
    const module = {exports: {}};
    const source = readFileSync(new URL(relative, import.meta.url), 'utf8');
    const compiled = ts.transpileModule(source, {compilerOptions: {module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022, jsx: ts.JsxEmit.ReactJSX, esModuleInterop: true}}).outputText;
    runInNewContext(compiled, {module, exports: module.exports, require: (id) => {
      if (id === '@mui/material') return mui;
      if (id === '@tanstack/react-query') return {
        useQuery: () => ({data: {carWash: currentShop, onboarding}, isFetching, error, refetch() {}}),
        useMutation: (options) => { captureMutation?.(options); return {isPending: false, mutate() {}}; },
        useQueryClient: () => ({invalidateQueries() {}}),
      };
      if (id === 'lucide-react') return new Proxy({}, {get: () => element('span')});
      if (id === '../../api/client') return {api: request || (() => { throw new Error('No network in rendering test'); })};
      if (id === '../common/StatusBadge') return {StatusBadge: () => null};
      if (id === '../../context/ToastContext') return {useToast: () => ({showSuccess() {}})};
      if (id === './OnboardingReadiness') return compile('../src/components/shops/OnboardingReadiness.tsx');
      return require(id);
    }});
    return module.exports;
  }
  const {ReviewModal} = compile('../src/components/shops/ReviewModal.tsx');
  return renderToStaticMarkup(React.createElement(ReviewModal, {shop, onClose() {}}));
}
function confirmationDisabled(html) {
  const button = html.match(/<button([^>]*)>Confirm Decision<\/button>/);
  assert.ok(button, 'review confirmation is rendered');
  return button[1].includes('disabled');
}

test('approval remains disabled until the latest complete setup is loaded', () => {
  assert.equal(confirmationDisabled(renderReview({isFetching: true})), true);
  assert.equal(confirmationDisabled(renderReview({onboarding: null})), true);
  assert.equal(confirmationDisabled(renderReview({error: new Error('Cannot load setup')})), true);
  assert.equal(confirmationDisabled(renderReview()), false);
});

test('incomplete setup explains missing requirements and prevents approval', () => {
  const html = renderReview({onboarding: {...ready, complete: false, issues: ['Add future booking slots.']}});
  assert.equal(confirmationDisabled(html), true);
  assert.match(html, /Add future booking slots/);
});

test('an application rejected while the modal was open cannot be approved', () => {
  const html = renderReview({currentShop: {...shop, status: 'rejected', review: {reason: 'Correct the map pin.'}}});
  assert.equal(confirmationDisabled(html), true);
  assert.match(html, /Correct the map pin/);
  assert.match(html, /correct and resubmit/);
});

test('review submits the fresh detail timestamp in canonical form, preserving nanoseconds', async () => {
  for (const updatedAt of [
    {_seconds: 1790780000, _nanoseconds: 123456789},
    {seconds: 1790780000, nanoseconds: 123456789},
  ]) {
    let mutation;
    let submitted;
    renderReview({
      currentShop: {...shop, updatedAt},
      captureMutation: (options) => { mutation = options; },
      request: async (path, init) => { submitted = {path, body: JSON.parse(init.body)}; },
    });
    await mutation.mutationFn();
    assert.deepEqual(submitted, {
      path: '/v1/admin/car-washes/shop-1/review',
      body: {decision: 'approve', expectedUpdatedAt: {seconds: 1790780000, nanoseconds: 123456789}},
    });
  }
});
