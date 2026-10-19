import '../../../matching/presentation/pages/match_success_page.dart'
    show MatchHeartSparkles;
import 'package:flutter/material.dart';
import '../../../../app/theme/coetus_tokens.dart';
import '../../domain/conversation_heart.dart';

class ConversationHeartBadge extends StatelessWidget {
  const ConversationHeartBadge({super.key, required this.heart});
  final ConversationHeart heart;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Sohbet kalbi, seviye ${heart.level}',
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: heart.level == 2 ? CoetusPalette.lime : CoetusPalette.cream,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            heart.level == 0 ? Icons.favorite_border : Icons.favorite,
            color: CoetusPalette.red,
          ),
          if (heart.level == 2)
            const SizedBox(width: 32, height: 32, child: MatchHeartSparkles()),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heart.level == 2
                      ? 'Pırıltılı sohbet kalbi'
                      : heart.level == 1
                      ? 'Sohbet kalbiniz doldu!'
                      : 'Sohbet kalbiniz büyüyor',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  heart.level == 2
                      ? 'İkiniz de en az 500 mesaj paylaştınız.'
                      : 'Sen: ${heart.mine} · Karşı taraf: ${heart.theirs} · Hedef: kişi başı ${heart.level == 0 ? 50 : 500} mesaj',
                  style: const TextStyle(fontSize: 11),
                ),
                if (heart.level < 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: LinearProgressIndicator(
                      value: heart.progress,
                      color: CoetusPalette.red,
                      backgroundColor: CoetusPalette.softLavender,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
