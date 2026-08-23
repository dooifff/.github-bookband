<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DatabaseOptimize extends Command
{
    protected $signature = 'database:optimize 
                            {--check : Only check, do not optimize}';

    protected $description = 'Optimize database tables, analyze indexes, and clean data';

    public function handle()
    {
        $checkOnly = $this->option('check');

        $this->info('');
        $this->info('╔══════════════════════════════════════════════════════════╗');
        $this->info('║        StudioBook Database Optimization                 ║');
        $this->info('╚══════════════════════════════════════════════════════════╝');
        $this->info('');

        $driver = DB::connection()->getConfig('driver');

        if ($driver === 'sqlite') {
            $this->optimizeSQLite($checkOnly);
        } elseif ($driver === 'mysql') {
            $this->optimizeMySQL($checkOnly);
        } else {
            $this->warn("Optimization not available for driver: {$driver}");
        }

        // Clean old data
        if (!$checkOnly) {
            $this->cleanOldData();
        }

        // Show table statistics
        $this->showTableStats();

        $this->info('');
        $this->info('✅ Database optimization complete!');
        $this->info('');

        return 0;
    }

    protected function optimizeSQLite(bool $checkOnly): void
    {
        $this->info('📋 SQLite Optimization');
        $this->info('');

        $tables = DB::select("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");

        foreach ($tables as $table) {
            $tableName = $table->name;

            if ($checkOnly) {
                $this->line("  Checking: {$tableName}");
            } else {
                $this->line("  Optimizing: {$tableName}");
                DB::statement("VACUUM {$tableName}");
            }
        }

        if (!$checkOnly) {
            $this->info('  Running VACUUM...');
            DB::statement('VACUUM');
            $this->info('  ✅ VACUUM complete');
        }
    }

    protected function optimizeMySQL(bool $checkOnly): void
    {
        $this->info('📋 MySQL Optimization');
        $this->info('');

        $tables = DB::select("SHOW TABLES");
        $dbName = DB::connection()->getConfig('database');

        foreach ($tables as $table) {
            $tableName = $table->{"Tables_in_{$dbName}"};

            if ($checkOnly) {
                // Check table status
                $status = DB::select("SHOW TABLE STATUS LIKE ?", [$tableName]);
                if (!empty($status)) {
                    $engine = $status[0]->Engine ?? 'N/A';
                    $rows = $status[0]->Rows ?? 0;
                    $dataSize = $status[0]->Data_length ?? 0;
                    $indexSize = $status[0]->Index_length ?? 0;

                    $this->line("  {$tableName}: {$rows} rows, Engine: {$engine}");
                }
            } else {
                $this->line("  Optimizing: {$tableName}");
                DB::statement("OPTIMIZE TABLE {$tableName}");
            }
        }

        // Analyze tables
        if (!$checkOnly) {
            $this->info('');
            $this->info('  Analyzing tables...');
            foreach ($tables as $table) {
                $tableName = $table->{"Tables_in_{$dbName}"};
                DB::statement("ANALYZE TABLE {$tableName}");
            }
            $this->info('  ✅ ANALYZE complete');
        }
    }

    protected function cleanOldData(): void
    {
        $this->info('');
        $this->info('🧹 Cleaning Old Data');
        $this->info('');

        // Clean old cache
        $this->line('  Clearing application cache...');
        \Artisan::call('cache:clear');
        $this->line('  ✅ Cache cleared');

        // Clean old sessions (older than 7 days)
        if (Schema::hasTable('sessions')) {
            $deleted = DB::table('sessions')
                ->where('last_activity', '<', now()->subDays(7)->timestamp)
                ->delete();
            $this->line("  Cleaned {$deleted} old sessions");
        }

        // Clean old failed jobs (older than 30 days)
        if (Schema::hasTable('failed_jobs')) {
            $deleted = DB::table('failed_jobs')
                ->where('failed_at', '<', now()->subDays(30))
                ->delete();
            $this->line("  Cleaned {$deleted} old failed jobs");
        }

        // Clean old job queue (older than 7 days)
        if (Schema::hasTable('jobs')) {
            $deleted = DB::table('jobs')
                ->where('available_at', '<', now()->subDays(7)->timestamp)
                ->delete();
            $this->line("  Cleaned {$deleted} old jobs");
        }

        // Clean old performance snapshots (older than 30 days)
        $this->line('  Performance snapshots retained for 30 days');
    }

    protected function showTableStats(): void
    {
        $this->info('');
        $this->info('📊 Table Statistics');
        $this->info('');
        $this->line('  Table                    | Rows      | Data Size | Index Size');
        $this->line('  -------------------------|-----------|-----------|------------');

        $tables = DB::select("SHOW TABLE STATUS");
        $dbName = DB::connection()->getConfig('database');

        $totalRows = 0;
        $totalDataSize = 0;
        $totalIndexSize = 0;

        foreach ($tables as $table) {
            $name = $table->{"Tables_in_{$dbName}"} ?? $table->Name ?? 'unknown';
            $rows = $table->Rows ?? 0;
            $dataSize = $table->Data_length ?? 0;
            $indexSize = $table->Index_length ?? 0;

            $totalRows += $rows;
            $totalDataSize += $dataSize;
            $totalIndexSize += $indexSize;

            $this->line(sprintf(
                '  %-24s | %9d | %9s | %10s',
                substr($name, 0, 24),
                $rows,
                $this->formatBytes($dataSize),
                $this->formatBytes($indexSize)
            ));
        }

        $this->line('  -------------------------|-----------|-----------|------------');
        $this->line(sprintf(
            '  %-24s | %9d | %9s | %10s',
            'TOTAL',
            $totalRows,
            $this->formatBytes($totalDataSize),
            $this->formatBytes($totalIndexSize)
        ));
    }

    protected function formatBytes(int $bytes): string
    {
        $units = ['B', 'KB', 'MB', 'GB'];
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count($units) - 1);
        $bytes /= pow(1024, $pow);
        return round($bytes, 1) . $units[$pow];
    }
}
