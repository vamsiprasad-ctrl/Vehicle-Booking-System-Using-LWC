import { LightningElement } from 'lwc';

export default class AboutPage extends LightningElement {

    get milestones() {
        return [
            { year: '1945', title: 'Founded', desc: 'Tata Engineering and Locomotive Company established in Jamshedpur.' },
            { year: '1954', title: 'First Truck', desc: 'First Tata truck rolled out — establishing India\'s commercial vehicle backbone.' },
            { year: '1991', title: 'Tata Sierra', desc: 'India\'s first sports utility vehicle — the iconic Tata Sierra launched.' },
            { year: '1998', title: 'Tata Indica', desc: 'India\'s first fully indigenous passenger car — a watershed moment in automotive history.' },
            { year: '2008', title: 'Tata Nano', desc: 'The world\'s most affordable car — making mobility accessible to every family.' },
            { year: '2017', title: 'Tata Nexon', desc: 'Launched India\'s first 5-star Global NCAP safety-rated car.' },
            { year: '2020', title: 'Nexon EV', desc: 'India\'s best-selling electric vehicle launched — leading the EV revolution.' },
            { year: '2024', title: 'EV Leadership', desc: 'India\'s #1 electric vehicle brand with the widest range of EVs in the country.' }
        ];
    }

    get siteBase() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        const prefix = match ? match[1] : 'tatasite';
        return window.location.origin + '/' + prefix;
    }

    navigate(page) { window.location.href = `${this.siteBase}/${page}`; }

    goHome()      { this.navigate(''); }
    goModels()    { this.navigate('models'); }
    goTestDrive() { this.navigate('book-test-drive'); }
}