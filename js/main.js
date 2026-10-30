$(function () {
    // 1. 스크롤 이벤트
    const speed = 600;

    // GNB / 로고 클릭 시 이동
    $('header .gnb a, .logo a').on('click', function (e) {
        e.preventDefault();

        const target = $(this).attr('href');

        $('html, body').stop(true, false);

        // 첫 페이지는 무조건 맨 위로 이동
        if (target === '#page01') {
            $.scrollTo(0, speed);
        } else {
            $.scrollTo(target, speed);
        }
    });

    function headerShowHide() {
        const scrollTop = $(window).scrollTop();
        const page02Top = $('#page02').offset().top;

        if (scrollTop >= page02Top - 100) {
            $('header').removeClass('header-hidden').addClass('header-visible');
        } else {
            $('header').removeClass('header-visible').addClass('header-hidden');
        }
    }

    $(window).on('scroll resize', headerShowHide);

    // 첫 화면(인트로)만 원페이지 스크롤: 인트로에서 휠을 내리면 소개로, 소개 맨 위에서 올리면 인트로로 한 번에 이동
    let introMoving = false;
    window.addEventListener('wheel', function (e) {
        if (window.innerWidth <= 1024 || window.matchMedia('(pointer: coarse)').matches) return;
        if (!$('#designModal').prop('hidden')) return;
        if (Math.abs(e.deltaX) > Math.abs(e.deltaY)) return;
        // 이동 중이거나 막 도착한 직후의 남은 휠(트랙패드 관성)은 무시
        if (introMoving) { e.preventDefault(); return; }

        const introEnd = $('#page02').offset().top;
        const y = $(window).scrollTop();
        const down = e.deltaY > 0;
        const inIntroZone = down ? y < introEnd - 1 : y > 0 && y <= introEnd + 1;
        if (!inIntroZone) return;

        e.preventDefault();
        introMoving = true;
        $('html, body').stop(true, false);
        $.scrollTo(down ? introEnd : 0, speed, {
            axis: 'y',
            onAfter: function () { setTimeout(function () { introMoving = false; }, 400); }
        });
    }, { passive: false });

    headerShowHide();

    // 2. 스크롤 시 메뉴 색상 자동 변경
    $(window).on('scroll', function () {
        const scrollTop = $(window).scrollTop();
        const $gnbLinks = $('.gnb li a');
        
        // 인트로 범위 내 초기화
        if (scrollTop < $('#page02').offset().top - 100) {
            $gnbLinks.each(function () {
                const img = $(this).find('img');
                img.attr('src', img.attr('src').replace('-on', '-off'));
            });
            $gnbLinks.removeClass('is-active').removeAttr('aria-current');
            return;
        }

        // 각 섹션별 색상 변경
        // [섹션, 메뉴 순서] — 프로젝트 섹션 두 개는 같은 '프로젝트' 메뉴를 켬
        [['#page02', 0], ['#page03', 1], ['#page04', 2], ['#page04-2', 2], ['#design', 3], ['#page05', 4]].forEach(([id, index]) => {
            const $section = $(id);
            if ($section.length === 0) return;
            const top = $section.offset().top - 100;
            const bottom = top + $section.outerHeight();

            if (scrollTop >= top && scrollTop < bottom) {
                $gnbLinks.each(function () {
                    const img = $(this).find('img');
                    img.attr('src', img.attr('src').replace('-on', '-off'));
                });
                const $current = $gnbLinks.eq(index);
                $current.find('img').attr('src', $current.find('img').attr('src').replace('-off', '-on'));
                $gnbLinks.removeClass('is-active').removeAttr('aria-current');
                $current.addClass('is-active').attr('aria-current', 'true');
            }
        });
    });

    // 별 배경: 화면에 고정된 별 (외부 라이브러리 없음)
    const starsHost = document.createElement('div');
    starsHost.className = 'site-stars';
    starsHost.setAttribute('aria-hidden', 'true');
    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    // 늘 같은 배치를 만드는 난수 (새로고침해도 별 위치가 같음)
    let seed = 7;
    const rand = () => {
        seed = (seed * 16807) % 2147483647;
        return (seed - 1) / 2147483646;
    };

    // [종류, 개수] — 작은 별 · 밝은 별 · ✦ 반짝이 별
    const starTypes = [['', reduceMotion ? 50 : 110], ['is-bright', 14], ['is-sparkle', 8]];
    starTypes.forEach(([type, count]) => {
        for (let i = 0; i < count; i++) {
            const star = document.createElement('span');
            star.className = ('site-star ' + type).trim();
            star.style.setProperty('--x', (rand() * 100).toFixed(2) + '%');
            star.style.setProperty('--y', (rand() * 100).toFixed(2) + '%');
            star.style.setProperty('--size', type === 'is-sparkle' ? (10 + rand() * 8).toFixed(1) + 'px'
                : type === 'is-bright' ? (2.4 + rand()).toFixed(1) + 'px' : (1 + rand() * 1.4).toFixed(1) + 'px');
            star.style.setProperty('--duration', (2 + rand() * 3).toFixed(2) + 's');   // 반짝이는 속도
            star.style.setProperty('--delay', (-rand() * 5).toFixed(2) + 's');
            starsHost.appendChild(star);
        }
    });

    document.body.prepend(starsHost);

    // 별똥별: 3~8초마다 화면 위쪽 아무 곳에서, 왼쪽 아래나 오른쪽 아래로 떨어짐
    function shootStar() {
        if (!document.hidden) {
            const star = document.createElement('span');
            star.className = 'site-shooting-star';
            const toRight = Math.random() < 0.5;
            const angle = toRight ? 20 + Math.random() * 40 : 120 + Math.random() * 40;   // 떨어지는 방향(도)
            const distance = 300 + Math.random() * 350;   // 떨어지는 거리(px)
            star.style.left = (10 + Math.random() * 80) + '%';
            star.style.top = (Math.random() * 45) + '%';
            star.style.setProperty('--length', (90 + Math.random() * 90) + 'px');
            starsHost.appendChild(star);

            // 머리(오른쪽 끝)를 기준점으로 방향을 돌린 뒤 그 방향으로 이동
            const turn = `translateX(-100%) rotate(${angle}deg)`;
            star.animate([
                {opacity: 0, transform: `${turn} translateX(0)`},
                {opacity: 1, offset: 0.15},
                {opacity: 0, transform: `${turn} translateX(${distance}px)`}
            ], {duration: 900 + Math.random() * 600, easing: 'ease-out'}).onfinish = () => star.remove();
        }
        setTimeout(shootStar, 3000 + Math.random() * 5000);   // 다음 별똥별까지 기다리는 시간
    }
    if (!reduceMotion) setTimeout(shootStar, 1500);

    // 내리면 나타나는 효과: 화면에 들어온 요소에 .is-in을 한 번만 붙임
    $('.about-left, .about-right, .skills-title, .skill-category, .design-subtitle, .design-grid, .contact-inner').addClass('reveal');
    const $reveals = $('.reveal');

    if ('IntersectionObserver' in window) {
        const revealObserver = new IntersectionObserver((entries) => {
            entries.forEach((entry) => {
                if (!entry.isIntersecting) return;
                entry.target.classList.add('is-in');
                revealObserver.unobserve(entry.target);
            });
        }, { threshold: 0.15 });
        $reveals.each(function () { revealObserver.observe(this); });
    } else {
        $reveals.addClass('is-in');
    }

    // 3. 디자인 작업물 크게 보기
    // 소하 상품 목업 (project_01/img 파일명 = 상품명)
    const mockups = [
        ['category_2024-diary', '2024 다이어리'],
        ['new_undated-daily-diary', '만년형 데일리 다이어리'],
        ['category_2024-weekly-diary', '2024 위클리 다이어리'],
        ['new_undated-simple-diary', '만년형 심플 다이어리'],
        ['cart_undated-work-planner', '만년 업무 플래너'],
        ['cart_project-tracker', '프로젝트 트래커'],
        ['new_domestic-travel-planner', '국내 여행 플래너'],
        ['category_office-work-log', '회사생활 업무일지'],
        ['new_bookshelf', '북쉘프'],
        ['cart_bullet-journal', '불렛저널'],
        ['category_movie-journal', '무비저널'],
        ['category_drama-review', '드라마 리뷰']
    ].map(([file, name]) => ({ src: `./project_01/img/${file}.jpg`, alt: `소하 상품 목업: ${name}` }));

    const galleries = {
        'soha-visual': {
            title: '소하 · 브랜드 비주얼',
            groups: [
                { name: '브랜드·상품 배너', items: [{ src: './img/design/soha-banner.jpg', alt: '소하 브랜드 소개 배너와 상품 배너' }] },
                { name: '메인 비주얼', items: [1, 2, 3, 4, 5, 6].map((n) => ({ src: `./project_01/img/02_main_visual0${n}.jpg`, alt: `소하 메인 비주얼 ${n}` })) },
                { name: '상품 목업', grid: true, items: mockups }
            ]
        },
        'soha-product': {
            title: '소하 · 상품 디자인',
            groups: [{ name: '디지털 속지', items: [{ src: './img/product.jpg', alt: '일주일 플래너, 습관 트래커, 위클리 속지' }] }]
        },
        'simda': {
            title: '심다 · 저축 습관 앱 UI',
            groups: [
                { name: '앱 화면', items: [{ src: './img/design/simda-app.jpg', alt: '심다 앱 화면 흐름' }] },
                { name: '스타일 가이드', items: [{ src: './img/style_guide.jpg', alt: '심다 타이포그래피, 컬러, 버튼 스타일 가이드' }] }
            ]
        },
        'graphic': {
            title: '개인 그래픽 작업',
            groups: [
                { name: '2026 롯데자이언츠 캘린더', items: [{ src: './img/design/calendar.jpg', alt: '롯데자이언츠 팀 컬러로 만든 야구 없는 날 캘린더' }] },
                { name: '미니 가계부', grid: true, items: [
                    { src: './img/design/budget.jpg', alt: '미니 가계부' },
                    { src: './img/design/budget-black.jpg', alt: '미니 가계부 블랙' }
                ] }
            ]
        }
    };

    const $modal = $('#designModal');
    const $modalBody = $modal.find('.design-modal-body');
    let $lastTrigger = null;

    function openGallery(key, $trigger) {
        const gallery = galleries[key];
        if (!gallery) return;

        $modal.find('#designModalTitle').text(gallery.title);
        $modalBody.empty();

        gallery.groups.forEach((group) => {
            $('<h4>').text(group.name).appendTo($modalBody);
            const $wrap = $('<div>').addClass(group.grid ? 'design-modal-grid' : 'design-modal-list').appendTo($modalBody);
            group.items.forEach((item) => {
                $('<img>', { src: item.src, alt: item.alt, loading: 'lazy' }).appendTo($wrap);
            });
        });

        $lastTrigger = $trigger;
        $modal.prop('hidden', false);
        $('body').addClass('modal-open');
        $modalBody.scrollTop(0);
        $modal.find('.design-modal-close').trigger('focus');
    }

    function closeGallery() {
        $modal.prop('hidden', true);
        $('body').removeClass('modal-open');
        if ($lastTrigger) $lastTrigger.trigger('focus');
    }

    $('.design-open, .design-thumb').on('click', function () {
        openGallery($(this).data('gallery'), $(this).closest('.design-card').find('.design-open'));
    });

    $modal.find('.design-modal-close').on('click', closeGallery);

    // 바깥 어두운 영역을 누르면 닫기
    $modal.on('click', function (e) {
        if (e.target === this) closeGallery();
    });

    $(document).on('keydown', function (e) {
        if (e.key === 'Escape' && !$modal.prop('hidden')) closeGallery();
    });
})