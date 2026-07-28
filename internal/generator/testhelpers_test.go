package generator

import (
	"context"

	"github.com/oscarcanton/anvilcli/internal/config"
)

// MARK: - Test Mocks

type mockXcodeProjGenerator struct {
	output     string
	err        error
	called     bool
	projectDir string
	cfg        config.ProjectConfig
}

func (m *mockXcodeProjGenerator) Generate(_ context.Context, projectDir string, cfg config.ProjectConfig) (string, error) {
	m.called = true
	m.projectDir = projectDir
	m.cfg = cfg
	return m.output, m.err
}

type mockGitRunner struct {
	initErr   error
	addErr    error
	commitErr error
	initDir   string
}

func (m *mockGitRunner) Init(dir string) error {
	m.initDir = dir
	return m.initErr
}

func (m *mockGitRunner) AddAll(dir string) error {
	return m.addErr
}

func (m *mockGitRunner) Commit(dir string, msg string) error {
	return m.commitErr
}

type mockMarkerReadWriter struct {
	writeErr error
	writeCfg config.AnvilMarker
	writeDir string
	readErr  error
	readData config.AnvilMarker
}

func (m *mockMarkerReadWriter) Write(dir string, marker config.AnvilMarker) error {
	m.writeDir = dir
	m.writeCfg = marker
	return m.writeErr
}

func (m *mockMarkerReadWriter) Read(dir string) (config.AnvilMarker, error) {
	return m.readData, m.readErr
}

func (m *mockMarkerReadWriter) FindProjectRoot(startDir string) (string, error) {
	return "", nil
}

type mockFeatureForge struct {
	result config.ForgeResult
	err    error
	called bool
	cfg    config.FeatureConfig
}

func (m *mockFeatureForge) Forge(cfg config.FeatureConfig) (config.ForgeResult, error) {
	m.called = true
	m.cfg = cfg
	return m.result, m.err
}

type mockPackRenderer struct {
	files  []string
	err    error
	called bool
	packs  []string
	scope  string
}

func (m *mockPackRenderer) RenderPacks(packs []string, skillsScope string, ctx any, projectDir string) ([]string, error) {
	m.called = true
	m.packs = packs
	m.scope = skillsScope
	return m.files, m.err
}
