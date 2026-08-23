<?php

namespace App\Console\Commands;

use App\Services\BookingReminderService;
use Illuminate\Console\Command;

class SendBookingReminders extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'bookings:send-reminders {--type=all : Type of reminder to send (all, upcoming, tomorrow, payment, cancel-expired)}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Send booking reminders to users';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $reminderService = new BookingReminderService();
        $type = $this->option('type');

        try {
            switch ($type) {
                case 'upcoming':
                    $reminderService->sendUpcomingBookingReminders();
                    $this->info('✅ Upcoming booking reminders sent successfully');
                    break;

                case 'tomorrow':
                    $reminderService->sendTomorrowBookingReminders();
                    $this->info('✅ Tomorrow booking reminders sent successfully');
                    break;

                case 'payment':
                    $reminderService->sendPaymentReminders();
                    $this->info('✅ Payment reminders sent successfully');
                    break;

                case 'cancel-expired':
                    $count = $reminderService->autoCancelExpiredBookings();
                    $this->info("✅ Auto-cancelled {$count} expired bookings");
                    break;

                case 'all':
                default:
                    $reminderService->sendUpcomingBookingReminders();
                    $reminderService->sendTomorrowBookingReminders();
                    $reminderService->sendPaymentReminders();
                    $count = $reminderService->autoCancelExpiredBookings();
                    $this->info('✅ All booking reminders processed successfully');
                    $this->info("   - Auto-cancelled: {$count} expired bookings");
                    break;
            }

            return Command::SUCCESS;
        } catch (\Exception $e) {
            $this->error("❌ Error: {$e->getMessage()}");
            return Command::FAILURE;
        }
    }
}
