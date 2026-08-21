import 'package:flutter/material.dart';
import 'package:namnam/core/Utility/appcolors.dart';
import 'package:namnam/model/merchant_request.dart';
import 'package:namnam/model/request/update_merchant_status_request.dart';
import 'package:namnam/model/zone.dart';
import 'package:namnam/viewmodel/zones_view_model.dart';
import 'package:provider/provider.dart';

/// Confirms an approve/reject decision and collects the zone that has to
/// accompany it. Pops with the chosen zone id, or null when cancelled — the
/// caller performs the PATCH so the request stays tied to a context that
/// outlives this dialog.
class MerchantRequestDecisionDialog extends StatefulWidget {
  final MerchantRequest request;
  final String status;

  const MerchantRequestDecisionDialog({
    super.key,
    required this.request,
    required this.status,
  });

  static Future<int?> show({
    required BuildContext context,
    required MerchantRequest request,
    required String status,
  }) {
    // The picker needs zones. homeWeb loads them at startup, but this dialog
    // can be reached before that finishes or after a failed load.
    final zonesViewModel = context.read<ZonesViewModel>();
    if (zonesViewModel.zones.isEmpty && !zonesViewModel.isLoading) {
      zonesViewModel.fetchZones();
    }

    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (_) => MerchantRequestDecisionDialog(
        request: request,
        status: status,
      ),
    );
  }

  @override
  State<MerchantRequestDecisionDialog> createState() =>
      _MerchantRequestDecisionDialogState();
}

class _MerchantRequestDecisionDialogState
    extends State<MerchantRequestDecisionDialog> {
  int? _selectedZoneId;
  bool _showZoneError = false;

  bool get _isApprove => widget.status == UpdateMerchantStatusRequest.approved;

  @override
  void initState() {
    super.initState();
    // Pre-select whatever zone the merchant already carries, if any.
    _selectedZoneId = widget.request.merchant?.zoneId;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isApprove ? Colors.green.shade700 : Colors.red.shade700;

    return Consumer<ZonesViewModel>(
      builder: (context, zonesViewModel, _) {
        final zones = zonesViewModel.zones
            .where((zone) => zone.zoneId != null)
            .toList();
        final zoneIds = zones.map((zone) => zone.zoneId!).toSet();

        // Only feed the dropdown a value it actually has an item for; zones
        // load asynchronously, so the pre-selected id may not be there yet.
        final selectedValue =
            _selectedZoneId != null && zoneIds.contains(_selectedZoneId)
                ? _selectedZoneId
                : null;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isApprove ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isApprove ? 'Approve this request?' : 'Reject this request?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummary(),
                const SizedBox(height: 16),
                if (zonesViewModel.isLoading && zones.isEmpty)
                  _buildLoadingZones()
                else if (zones.isEmpty)
                  _buildNoZones()
                else
                  _buildZoneDropdown(zones, selectedValue),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              onPressed: zones.isEmpty
                  ? null
                  : () {
                      if (selectedValue == null) {
                        setState(() => _showZoneError = true);
                        return;
                      }
                      Navigator.of(context).pop(selectedValue);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
              ),
              child: Text(_isApprove ? 'Approve' : 'Reject'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummary() {
    final merchant = widget.request.merchant;
    final requestLabel = widget.request.requestId != null
        ? 'Request #${widget.request.requestId}'
        : 'Request';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            merchant?.name ?? 'Unnamed Merchant',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Appcolors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            merchant?.merchantId != null
                ? '$requestLabel · Merchant #${merchant!.merchantId}'
                : requestLabel,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingZones() {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(
          'Loading zones…',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildNoZones() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No zones available. Create a zone first — this endpoint requires one.',
              style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneDropdown(List<Zone> zones, int? selectedValue) {
    return DropdownButtonFormField<int>(
      initialValue: selectedValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Zone *',
        hintText: 'Select a zone',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.map_outlined),
        errorText: _showZoneError && selectedValue == null
            ? 'Pick a zone to continue'
            : null,
      ),
      items: [
        for (final zone in zones)
          DropdownMenuItem<int>(
            value: zone.zoneId!,
            child: Text(
              zone.zoneName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) => setState(() {
        _selectedZoneId = value;
        _showZoneError = false;
      }),
    );
  }
}
