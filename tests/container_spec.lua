local container = require('neo-symfony.features.container')
local cache = require('neo-symfony.cache')

local FIXTURE_XML = vim.fn.getcwd() .. '/tests/fixtures/AppKernelDevDebugContainer.xml'

local function make_tmpdir()
  local t = '/tmp/neo-symfony-test-' .. os.time() .. '-' .. math.random(10000)
  vim.fn.mkdir(t .. '/var/cache/dev', 'p')
  vim.fn.system('cp ' .. FIXTURE_XML .. ' ' .. t .. '/var/cache/dev/AppKernelDevDebugContainer.xml')
  return t
end

local function teardown(tmpdir)
  cache.invalidate('container', tmpdir)
  vim.fn.system('rm -rf ' .. tmpdir)
end

describe('container.get_services', function()

  it('returns empty table when no container XML is found', function()
    local result = container.get_services('/tmp/not-a-symfony-project-' .. os.time())
    assert.are.same({}, result)
  end)

  it('extracts id, class and public flag from each service', function()
    local tmpdir = make_tmpdir()
    local services = container.get_services(tmpdir)

    assert.is_true(#services > 0)

    local by_id = {}
    for _, s in ipairs(services) do by_id[s.id] = s end

    local user_svc = by_id['App\\Service\\UserService']
    assert.is_not_nil(user_svc)
    assert.are.equal('App\\Service\\UserService', user_svc.class)
    assert.is_true(user_svc.public)

    local repo = by_id['App\\Repository\\UserRepository']
    assert.is_not_nil(repo)
    assert.are.equal('App\\Repository\\UserRepository', repo.class)
    assert.is_false(repo.public)

    teardown(tmpdir)
  end)

  it('extracts tags as attribute tables for each service', function()
    local tmpdir = make_tmpdir()
    local services = container.get_services(tmpdir)

    local by_id = {}
    for _, s in ipairs(services) do by_id[s.id] = s end

    local user_svc = by_id['App\\Service\\UserService']
    assert.are.equal(2, #user_svc.tags)
    assert.are.equal('kernel.event_listener', user_svc.tags[1].name)
    assert.are.equal('kernel.request', user_svc.tags[1].event)
    assert.are.equal('monolog.logger', user_svc.tags[2].name)
    assert.are.equal('app', user_svc.tags[2].channel)

    local repo = by_id['App\\Repository\\UserRepository']
    assert.are.equal(1, #repo.tags)
    assert.are.equal('doctrine.repository_service', repo.tags[1].name)

    local mailer = by_id['App\\Service\\MailerService']
    assert.are.equal(0, #mailer.tags)

    teardown(tmpdir)
  end)

  it('returns cached results on second call even after XML is deleted', function()
    local tmpdir = make_tmpdir()

    local first = container.get_services(tmpdir)
    assert.is_true(#first > 0)

    vim.fn.system('rm ' .. tmpdir .. '/var/cache/dev/AppKernelDevDebugContainer.xml')

    local second = container.get_services(tmpdir)
    assert.are.equal(#first, #second)
    assert.are.equal(first[1].id, second[1].id)

    teardown(tmpdir)
  end)

  it('re-parses after cache is invalidated and var/cache/dev is touched', function()
    local tmpdir = make_tmpdir()

    -- populate and write to disk
    local first = container.get_services(tmpdir)
    assert.is_true(#first > 0)

    -- invalidate in-mem and disk cache
    cache.invalidate('container', tmpdir)

    -- touch var/cache/dev so disk_stale() returns true
    vim.fn.system('touch ' .. tmpdir .. '/var/cache/dev')

    -- replace XML with a single-service version
    local minimal_xml = [[<?xml version="1.0" encoding="utf-8"?>
<container xmlns="http://symfony.com/schema/dic/services">
  <services>
    <service id="App\Service\OnlyThis" class="App\Service\OnlyThis" public="true">
    </service>
  </services>
</container>]]
    local f = io.open(tmpdir .. '/var/cache/dev/AppKernelDevDebugContainer.xml', 'w')
    f:write(minimal_xml)
    f:close()

    local second = container.get_services(tmpdir)
    assert.are.equal(1, #second)
    assert.are.equal('App\\Service\\OnlyThis', second[1].id)

    teardown(tmpdir)
  end)

end)
